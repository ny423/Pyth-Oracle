use {
    super::State,
    crate::aggregate::Update,
    anyhow::{
        anyhow,
        Result,
    },
    pythnet_sdk::wire::v1::{
        WormholeMessage,
        WormholePayload,
    },
    secp256k1::{
        ecdsa::{
            RecoverableSignature,
            RecoveryId,
        },
        Message,
        Secp256k1,
    },
    serde_wormhole::RawMessage,
    sha3::{
        Digest,
        Keccak256,
    },
    std::sync::Arc,
    tracing::trace,
    wormhole_sdk::{
        vaa::{
            Body,
            Header,
        },
        Address,
        Chain,
        Vaa,
    },
};


pub type VaaBytes = Vec<u8>;
const OBSERVED_CACHE_SIZE: usize = 1000;

#[derive(Eq, PartialEq, Clone, Hash, Debug)]
pub struct GuardianSet {
    pub keys: Vec<[u8; 20]>,
}

impl std::fmt::Display for GuardianSet {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[")?;
        for (i, key) in self.keys.iter().enumerate() {
            // Comma seperated printing of the keys using hex encoding.
            if i != 0 {
                write!(f, ", ")?;
            }

            write!(f, "{}", hex::encode(key))?;
        }
        write!(f, "]")
    }
}

/// BridgeData extracted from wormhole bridge account, due to no API.
#[derive(borsh::BorshDeserialize)]
#[allow(dead_code)]
pub struct BridgeData {
    pub guardian_set_index: u32,
    pub last_lamports:      u64,
    pub config:             BridgeConfig,
}

/// BridgeConfig extracted from wormhole bridge account, due to no API.
#[derive(borsh::BorshDeserialize)]
#[allow(dead_code)]
pub struct BridgeConfig {
    pub guardian_set_expiration_time: u32,
    pub fee:                          u64,
}

/// GuardianSetData extracted from wormhole bridge account, due to no API.
#[derive(borsh::BorshDeserialize)]
pub struct GuardianSetData {
    pub index:           u32,
    pub keys:            Vec<[u8; 20]>,
    pub creation_time:   u32,
    pub expiration_time: u32,
}

/// Verifies a VAA to ensure it is signed by the Wormhole guardian set.
pub async fn verify_vaa<'a>(
    state: &State,
    vaa: Vaa<&'a RawMessage>,
) -> Result<Vaa<&'a RawMessage>> {
    let (header, body): (Header, Body<&RawMessage>) = vaa.into();
    let digest = body.digest()?;
    let guardian_set = state.guardian_set.read().await;
    let guardian_set = guardian_set
        .get(&header.guardian_set_index)
        .ok_or_else(|| {
            anyhow!(
                "Message signed by an unknown guardian set: {}",
                header.guardian_set_index
            )
        })?;

    // TODO: This check bypass checking the signatures on tests.
    // Ideally we need to test the signatures but currently Wormhole
    // doesn't give us any easy way for it.
    let quorum = if cfg!(test) {
        0
    } else {
        (guardian_set.keys.len() * 2) / 3 + 1
    };

    let mut last_signer_id: Option<usize> = None;
    let mut signatures = vec![];
    for signature in header.signatures.into_iter() {
        // Do not collect more signatures than necessary to reduce
        // on-chain gas spent on signature verification.
        if signatures.len() >= quorum {
            break;
        }

        let signer_id: usize = signature.index.into();

        if signer_id >= guardian_set.keys.len() {
            return Err(anyhow!(
                "Signer ID is out of range. Signer ID: {}, guardian set size: {}",
                signer_id,
                guardian_set.keys.len()
            ));
        }

        if let Some(true) = last_signer_id.map(|v| v >= signer_id) {
            return Err(anyhow!(
                "Signatures are not sorted by signer ID. Last signer ID: {:?}, current signer ID: {}",
                last_signer_id,
                signer_id
            ));
        }

        let sig = signature.signature;

        // Recover the public key from ecdsa signature from [u8; 65] that has (v, r, s) format
        let recid = RecoveryId::from_i32(sig[64].into())?;

        let secp = Secp256k1::new();

        // To get the address we need to use the uncompressed public key
        let pubkey: &[u8; 65] = &secp
            .recover_ecdsa(
                &Message::from_slice(&digest.secp256k_hash)?,
                &RecoverableSignature::from_compact(&sig[..64], recid)?,
            )?
            .serialize_uncompressed();

        // The address is the last 20 bytes of the Keccak256 hash of the public key
        let mut keccak = Keccak256::new();
        keccak.update(&pubkey[1..]);
        let address: [u8; 32] = keccak.finalize().into();
        let address: [u8; 20] = address[address.len() - 20..].try_into()?;

        if guardian_set.keys.get(signer_id) == Some(&address) {
            signatures.push(signature);
        }

        last_signer_id = Some(signer_id);
    }

    // Check if we have enough correct signatures
    if signatures.len() < quorum {
        return Err(anyhow!(
            "Not enough correct signatures. Expected {:?}, received {:?}",
            quorum,
            signatures.len()
        ));
    }

    Ok((
        Header {
            signatures,
            ..header
        },
        body,
    )
        .into())
}

/// Update the guardian set with the given ID in the state.
pub async fn update_guardian_set(state: &State, id: u32, guardian_set: GuardianSet) {
    let mut guardian_sets = state.guardian_set.write().await;
    guardian_sets.insert(id, guardian_set);
}

/// Process a VAA from the Wormhole p2p and aggregate it if it is
/// verified and is new and belongs to the Accumulator.
pub async fn forward_vaa(state: Arc<State>, vaa_bytes: VaaBytes) {
    // Deserialize VAA
    let vaa = match serde_wormhole::from_slice::<Vaa<&serde_wormhole::RawMessage>>(&vaa_bytes) {
        Ok(vaa) => vaa,
        Err(e) => {
            tracing::error!(error = ?e, "Failed to deserialize VAA.");
            return;
        }
    };

    if vaa.emitter_chain != Chain::Pythnet
        || vaa.emitter_address != Address(pythnet_sdk::ACCUMULATOR_EMITTER_ADDRESS)
    {
        return; // Ignore VAA from other emitters
    }

    // Get the slot from the VAA.
    let slot = match WormholeMessage::try_from_bytes(vaa.payload)
        .unwrap()
        .payload
    {
        WormholePayload::Merkle(proof) => proof.slot,
    };

    // Find the observation time for said VAA (which is a unix timestamp) and serialize as a ISO 8601 string.
    let vaa_timestamp = vaa.timestamp;
    let vaa_timestamp = chrono::NaiveDateTime::from_timestamp_opt(vaa_timestamp as i64, 0).unwrap();
    let vaa_timestamp = vaa_timestamp.format("%Y-%m-%dT%H:%M:%S.%fZ").to_string();
    tracing::info!(slot = slot, vaa_timestamp = vaa_timestamp, "Observed VAA");

    if state.observed_vaa_seqs.read().await.contains(&vaa.sequence) {
        return; // Ignore VAA if we have already seen it
    }

    let vaa = match verify_vaa(&state, vaa).await {
        Ok(vaa) => vaa,
        Err(e) => {
            trace!(error = ?e, "Ignoring invalid VAA.");
            return;
        }
    };

    {
        let mut observed_vaa_seqs = state.observed_vaa_seqs.write().await;

        // Check again if we have already seen the VAA. Due to concurrency
        // the above check might not catch all the cases.
        if observed_vaa_seqs.contains(&vaa.sequence) {
            return; // Ignore VAA if we have already seen it
        }
        observed_vaa_seqs.insert(vaa.sequence);
        while observed_vaa_seqs.len() > OBSERVED_CACHE_SIZE {
            observed_vaa_seqs.pop_first();
        }
    }

    let state = state.clone();
    tokio::spawn(async move {
        if let Err(e) = crate::aggregate::store_update(&state, Update::Vaa(vaa_bytes)).await {
            tracing::error!(error = ?e, "Failed to process VAA.");
        }
    });
}

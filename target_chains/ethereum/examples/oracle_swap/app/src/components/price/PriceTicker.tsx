import { Price } from "@pythnetwork/pyth-evm-js";
import { timeAgo } from "../../utils/utils";

export function PriceTicker(props: {
    price: Price | undefined;
    currentTime: Date;
    tokenName: string;
}) {
    const price = props.price;

    if (price === undefined) {
        return <span style={{ color: "grey" }}>loading...</span>;
    } else {
        const now = props.currentTime.getTime() / 1000;

        return (
            <div>
                <p>
                    Pyth {props.tokenName} price:{" "}
                    <span style={{ color: "green" }}>
                        {" "}
                        {price.getPriceAsNumberUnchecked().toFixed(3) +
                            " ± " +
                            price.getConfAsNumberUnchecked().toFixed(3)}{" "}
                    </span>
                </p>
                <p>
                    <span style={{ color: "grey" }}>
                        last updated {timeAgo(now - price.publishTime)} ago
                    </span>
                </p>
            </div>
        );
    }
}

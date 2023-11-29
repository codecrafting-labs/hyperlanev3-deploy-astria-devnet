#!/bin/bash

AGENT_VERSION="3b1b8dc-20231115-202111"
CHAIN_NAMES=("cclabs01" "cclabs02")
CONFIG_FILE=$(basename $(find ./artifacts -name "agent-config-*.json" | sort))

for CHAIN in "${CHAIN_NAMES[@]}"
do
    mkdir -p /tmp/hyperlane/$CHAIN/validator && \
    chmod -R 777 /tmp/hyperlane/$CHAIN
done

for CHAIN in "${CHAIN_NAMES[@]}"
do
    echo "Running validator on rollup $CHAIN"
    CONTAINER_NAME="hyperlane-validator-$CHAIN"

    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "Container $CONTAINER_NAME is already running"
    else
        echo "Container $CONTAINER_NAME is not running. Starting."
        docker rm -f $CONTAINER_NAME
        # Won't work on anything but linux due to -net=host
        docker run -d --name $CONTAINER_NAME \
          --mount type=bind,source="$(pwd)/artifacts",target=/config \
          --mount type=bind,source="/tmp/hyperlane",target=/data --net=host \
          -e CONFIG_FILES=/config/$CONFIG_FILE \
          -e HYP_ORIGINCHAINNAME=$CHAIN \
          -e HYP_REORGPERIOD=0 \
          -e HYP_INTERVAL=1 \
          -e HYP_VALIDATOR_TYPE=hexKey \
          -e HYP_VALIDATOR_KEY=$HYP_KEY \
          -e HYP_CHECKPOINTSYNCER_TYPE=localStorage \
          -e HYP_CHECKPOINTSYNCER_PATH=/data/$CHAIN/validator \
          -e HYP_BASE_TRACING_LEVEL=info \
          -e HYP_BASE_TRACING_FMT=pretty \
          gcr.io/abacus-labs-dev/hyperlane-agent:$AGENT_VERSION ./validator
    fi
done

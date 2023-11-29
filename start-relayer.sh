#!/bin/bash

AGENT_VERSION="3b1b8dc-20231115-202111"
CHAIN_NAMES=("cclabs01" "cclabs02")

CONFIG_FILE=$(basename $(find ./artifacts -name "agent-config-*.json" | sort))

CHAIN_NAMES_STR="${CHAIN_NAMES[0]}"
for ((i=1; i<${#CHAIN_NAMES[@]}; i++)); do
  CHAIN_NAMES_STR+=",${CHAIN_NAMES[i]}"
done

mkdir -p /tmp/hyperlane/relayer

echo "Running relayer"
docker rm -f hyperlane-relayer
docker run -d --name hyperlane-relayer \
  --mount type=bind,source="$(pwd)/artifacts",target=/config \
  --mount type=bind,source="/tmp/hyperlane",target=/data --net=host \
  -e CONFIG_FILES=/config/$CONFIG_FILE \
  -e HYP_TRACING_LEVEL=debug \
  -e HYP_TRACING_FMT=pretty \
  -e HYP_RELAYCHAINS=sepolia,$CHAIN_NAMES_STR \
  -e HYP_ALLOWLOCALCHECKPOINTSYNCERS=true \
  -e HYP_DB=/data/relayer \
  -e HYP_GASPAYMENTENFORCEMENT='[{"type":"none"}]' \
  -e HYP_DEFAULTSIGNER_TYPE=hexKey \
  -e HYP_DEFAULTSIGNER_KEY=$HYP_KEY \
  gcr.io/abacus-labs-dev/hyperlane-agent:$AGENT_VERSION ./relayer

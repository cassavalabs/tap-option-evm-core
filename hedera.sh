#!/bin/bash

while getopts ":c:u:e:k:" opt; do
  case $opt in
    u) rpc="$OPTARG"
    ;;
    e) etherscan_key="$OPTARG"
    ;;
    k) private_key="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    exit 1
    ;;
  esac

  case $OPTARG in
    -*) echo "Option $opt needs a valid argument" >&2
    exit 1
    ;;
  esac
done

if [ -z ${private_key+x} ];
then
    echo "private key (-k) is unset" >&2
    exit 1
fi

set -euo pipefail

ROOT=$(dirname $0)
FORGE_SCRIPTS=$ROOT/script

. $ROOT/.hedera.env

# Use the RPC environment variable if rpc isn't set.
if [ -z ${rpc+x} ];
then
    rpc=$RPC
fi

# Use the verfifier url environment variable if verifier_url isn't set.
if [ -z ${verifier_url+x} ];
then
    verifier_url=$VERIFIER_URL
fi

forge script $FORGE_SCRIPTS/DeployOptionMarket.s.sol \
    --rpc-url $rpc \
    --broadcast \
    --private-key $private_key \
    --verify --verifier sourcify --verifier-url $verifier_url \
    --slow \
    --skip test
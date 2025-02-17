#!/bin/bash

HRP="erd"

# Obtener el código hexadecimal como argumento
HEX_CODE=$1

if [[ -z "$HEX_CODE" ]]; then
    echo "❌ Error: Debes proporcionar un código hexadecimal."
    exit 1
fi

BECH32_ADDRESS=$(python3 - <<EOF
from bech32 import bech32_encode, convertbits

hrp = "$HRP"
hex_data = bytes.fromhex("$HEX_CODE")
data = convertbits(hex_data, 8, 5, True)
print(bech32_encode(hrp, data))
EOF
)

echo "$BECH32_ADDRESS"

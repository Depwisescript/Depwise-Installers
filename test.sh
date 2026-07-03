#!/bin/bash
set -euo pipefail
FIREBASE_URL="https://keys-depwise-default-rtdb.firebaseio.com"
INSTALL_KEY="KEY-GEU8Q8CDEU"
if ! KEY_RESPONSE=$(curl -s -m 10 "${FIREBASE_URL}/keys/${INSTALL_KEY}.json"); then
    echo "FAILED"
else
    echo "SUCCESS: $KEY_RESPONSE"
fi

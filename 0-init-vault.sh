#!/bin/bash

if [ -f vault.pid ]; then
  echo "Vault PID file already exists"
  exit 1
fi

export VAULT_LOG_LEVEL=debug

./vault-ent-173 server -dev -dev-root-token-id=root -dev-listen-address="0.0.0.0:8200" >./vault.log 2>&1 &

echo $! > vault.pid

sleep 5

echo "Vault started with PID:$(cat vault.pid)"



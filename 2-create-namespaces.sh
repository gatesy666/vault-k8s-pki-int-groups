#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200

unset VAULT_NAMESPACE

vault login root

vault namespace create prd

export VAULT_NAMESPACE="prd"

vault namespace create app1

unset VAULT_NAMESPACE
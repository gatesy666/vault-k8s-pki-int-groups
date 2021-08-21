#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200

export EXTERNAL_VAULT_ADDR=http://$(minikube ssh "dig +short host.docker.internal" | tr -d '\r'):8200

unset VAULT_NAMESPACE

export VAULT_NAMESPACE="prd"

vault login root

vault secrets enable pki

#vault secrets tune -max-lease-ttl=20m pki

# Configure self-signed root CA on PKI secrets engine mounted on root namespace

vault write -format=json pki/root/generate/internal \
  common_name=my-website.com \
  ttl=8760h

vault write pki/config/urls \
  issuing_certificates="${EXTERNAL_VAULT_ADDR}/v1/pki/ca" \
  crl_distribution_points="${EXTERNAL_VAULT_ADDR}/v1/pki/crl"

vault write pki/roles/example-dot-com \
  allowed_domains=my-website.com \
  allow_bare_domains=true \
  allow_subdomains=false \
  max_ttl=72h


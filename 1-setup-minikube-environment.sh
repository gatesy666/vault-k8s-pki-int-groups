#!/bin/sh

minikube start --driver=docker 
sleep 5
# Get Vault Server IP
# export EXTERNAL_VAULT_ADDR="http://${LOCAL_IP}:8200"
export EXTERNAL_VAULT_ADDR=http://$(minikube ssh "dig +short host.docker.internal" | tr -d '\r'):8200
echo "EXTERNAL_VAULT_ADDR: ${EXTERNAL_VAULT_ADDR}"

# Set up service accounts
kubectl create sa vault-auth
kubectl create sa vault-agent-auth
kubectl apply -f configs/vault-service-accounts.yaml

# Label namespace to ensure Vault agent webhook works
kubectl label namespace default vault.hashicorp.com/agent-webhook=enabled

# Deploy Vault Agent Injector
# helm repo add hashicorp https://helm.releases.hashicorp.com
# helm repo update
helm install vault hashicorp/vault \
  --set "injector.externalVaultAddr=${EXTERNAL_VAULT_ADDR}"

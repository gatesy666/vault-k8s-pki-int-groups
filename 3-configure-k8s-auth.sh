#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200

unset VAULT_NAMESPACE
export VAULT_NAMESPACE="prd"

vault login root

# Configure policies for both Vault Agent and Cert Manager
vault policy write vault-agent-policy - <<EOF

path "pki/issue/example-dot-com" {
  capabilities = ["create","update"]
}

EOF

# Create some dummy test data on kv store

vault secrets enable -path=secret kv

vault kv put secret/myapp/config username='appuser' \
        password='suP3rsec(et!' \

# Get some things things we need from Kubernetes to configure Vault Auth Methods

export VAULT_SA_NAME=$(kubectl get sa vault-auth -o json | jq -r '.secrets[] | select(.name|test(".token.")) | .name')
echo $VAULT_SA_NAME

export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME \
    -o jsonpath="{.data.token}" | base64 -d)
echo $SA_JWT_TOKEN

export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME \
    -o jsonpath="{.data['ca\.crt']}" | base64 -d)

echo $SA_CA_CRT

export MINIKUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')

echo $MINIKUBE_HOST

# Enable the Kubernetes Authentication Method
vault auth enable kubernetes

# Configure Kubernetes Authentication Method
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="${MINIKUBE_HOST}" \
  kubernetes_ca_cert="${SA_CA_CRT}"

# Configure roles for both vault-agent and cert-manager

vault write auth/kubernetes/role/vault-agent-auth \
  bound_service_account_names=vault-agent-auth \
  bound_service_account_namespaces=default \
  policies=vault-agent-policy \
  ttl=24h
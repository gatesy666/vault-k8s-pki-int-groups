#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200
# if [ ! -f "my_ip.txt" ]
# then
#   echo "Please set your local ip in a file called my_ip.txt"
#   exit 1
# fi

# Get vault-agent-auth k8s sa uid

export KUBERNETES_SA_UID=$(kubectl get sa/vault-agent-auth -o json | jq -r ".metadata.uid")

vault login root

# Get mount accessor for Kubernetes auth method

export VAULT_NAMESPACE="prd"

export KUBERNETES_AUTH_ACCESSOR=$(vault auth list -format=json \
  | jq -r '.["kubernetes/"].accessor')

# Create k8s app entity

export CANONICAL_ID=$(vault write identity/entity name="k8s-app1" metdata=AppName="app1: a sample app" metadata=env="prd" -format=json | jq -r ".data.id")

# Add k8s SA UIDs to entity

vault write identity/entity-alias name=${KUBERNETES_SA_UID} canonical_id=${CANONICAL_ID} mount_accessor=${KUBERNETES_AUTH_ACCESSOR}

# Create a group with the vault-agent entity as a member

export VAULT_NAMESPACE="prd/app1"

vault policy write va-app1-policy - <<EOF
path "secret/*" {
  capabilities = ["read", "list"]
}

path "secret/app1/*" {
  capabilities = ["create","update","read","list","delete","sudo"]
}

path "sys/capabilities-self" {
    capabilities = ["create","update","read","list","delete","sudo"]
}
EOF

vault secrets enable -path=secret kv

vault kv put secret/app1 username='thisisa' \
        password='secret!!!' \

vault write identity/group \
  name="prd-k8s-vault-agents" policies="va-app1-policy" \
  member_entity_ids="${CANONICAL_ID}"
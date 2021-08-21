#!/bin/sh

# Apply vault-agent demo configurations

kubectl apply -f configs/www-vault-agent-colin-testing.yaml
sleep 30
echo ""
echo try curl -k or open your browser to this address: https://$(docker port minikube|grep 32443|cut -d " " -f3)
#!/bin/bash
set -e

namespace=""
version=""

# Parse named arguments
for arg in "$@"; do
    case $arg in
        --namespace=*)
        namespace="${arg#*=}"
        ;;
        --version=*)
        version="${arg#*=}"
        ;;
        *)
        # Unknown option
        echo "Unknown option: $arg"
        ;;
    esac
done

# Validate required arguments
if [[ -z "$namespace" || -z "$version" ]]; then
    echo "Usage: $0 --namespace=<namespace> --version=<version>"
    echo "Example: $0 --namespace=rhdh --version=1.5"
    exit 1
fi

source ../.env

# Create or switch to the specified namespace
oc new-project "$namespace" || oc project "$namespace"


curl -LO https://raw.githubusercontent.com/redhat-developer/rhdh-operator/refs/heads/release-$version/.rhdh/scripts/install-rhdh-catalog-source.sh
chmod +x install-rhdh-catalog-source.sh
./install-rhdh-catalog-source.sh -v $version --install-operator rhdh

# Apply secrets
envsubst < rhdh-secrets.yaml | oc apply -f -

# Create configmap with environment variables substituted
oc create configmap app-config-rhdh \
    --from-file="app-config-rhdh.yaml"=<(envsubst '${RHDH_BASE_URL}' < app-config-rhdh.yaml) \
    --namespace="$namespace" \
    --dry-run=client -o yaml | oc apply -f -

oc create configmap dynamic-plugins \
    --from-file="dynamic-plugins.yaml"=<(envsubst '${RHDH_BASE_URL}' < dynamic-plugins.yaml) \
    --namespace="$namespace" \
    --dry-run=client -o yaml | oc apply -f -

echo "done"

# oc apply -f "subscription.yaml" -n "$namespace"



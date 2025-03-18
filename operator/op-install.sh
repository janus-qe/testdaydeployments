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

# Get cluster router base and set RHDH URL
CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')
export RHDH_BASE_URL="https://backstage-developer-hub-${namespace}.${CLUSTER_ROUTER_BASE}"

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

timeout 300 bash -c '
while ! oc get crd/backstages.rhdh.redhat.com -n "${namespace}" >/dev/null 2>&1; do
    echo "Waiting for Backstage CRD to be created..."
    sleep 20
done
echo "Backstage CRD is created."
' || echo "Error: Timed out waiting for Backstage CRD creation."

oc apply -f "subscription.yaml" -n "$namespace"

echo "
RHDH_BASE_URL : 
$RHDH_BASE_URL
"

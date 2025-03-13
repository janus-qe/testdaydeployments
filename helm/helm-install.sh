#!/bin/bash
set -e

namespace=""
CV=""

# Parse named arguments
for arg in "$@"; do
    case $arg in
        --namespace=*)
        namespace="${arg#*=}"
        ;;
        --CV=*)
        CV="${arg#*=}"
        ;;
        *)
        # Unknown option
        echo "Unknown option: $arg"
        ;;
    esac
done

# Validate required arguments
if [[ -z "$namespace" || -z "$CV" ]]; then
    echo "Usage: $0 --namespace=<namespace> --CV=<cv-version>"
    echo "Example: $0 --namespace=rhdh --CV=1.5-171-CI"
    exit 1
fi

source ../.env

# Create or switch to the specified namespace
oc new-project "$namespace" || oc project "$namespace"

# Set up chart URL using the CV version
CHART_URL="https://github.com/rhdh-bot/openshift-helm-charts/raw/redhat-developer-hub-${CV}/charts/redhat/redhat/redhat-developer-hub/${CV}/redhat-developer-hub-${CV}.tgz"
oc apply -f "https://github.com/rhdh-bot/openshift-helm-charts/raw/redhat-developer-hub-${CV}/installation/rhdh-next-ci-repo.yaml"

# Get cluster router base and set RHDH URL
CLUSTER_ROUTER_BASE=$(oc get route console -n openshift-console -o=jsonpath='{.spec.host}' | sed 's/^[^.]*\.//')
export RHDH_BASE_URL="https://redhat-developer-hub-${namespace}.${CLUSTER_ROUTER_BASE}"

# Apply secrets
envsubst < rhdh-secrets.yaml | oc apply -f -

# Create configmap with environment variables substituted
oc create configmap app-config-rhdh \
    --from-file="app-config-rhdh.yaml"=<(envsubst '${RHDH_BASE_URL}' < app-config-rhdh.yaml) \
    --namespace="$namespace" \
    --dry-run=client -o yaml | oc apply -f -

# Install/upgrade Helm chart
helm upgrade redhat-developer-hub -i "${CHART_URL}" --version "$CV" \
    -f "value_file.yaml" \
    --set global.clusterRouterBase="${CLUSTER_ROUTER_BASE}"


echo "
Once deployed, Developer Hub $CV will be available at
https://redhat-developer-hub-${namespace}.${CLUSTER_ROUTER_BASE}
"
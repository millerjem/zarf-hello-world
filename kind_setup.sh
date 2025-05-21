#!/bin/bash

# Function to get latest kind version
get_latest_kind_version() {
    curl -Ls --fail 'https://hub.docker.com/v2/repositories/kindest/node/tags/?page_size=1000' | \
    jq '.results | .[] | .name' -r | \
    sed 's/latest//' | \
    sort --version-sort | \
    tail -n 1 | \
    awk -F. '{$NF = $NF ;} 1' OFS=. | \
    sed 's/\.$/.0/'
}

# Function to create kind cluster
alias kcc='kind_setup'
kind_setup() {
    local CLUSTER_NAME=${1:-$(basename "$PWD")}
    local CLUSTER_VERSION=${2:-$(get_latest_kind_version)}
    local REGION=${3:-us-gov-east-1}

    # Convert cluster name to lowercase and replace hyphens
    local CN=${CLUSTER_NAME//-/}
    CN=${CN:l}

    echo "Creating cluster... ${CN}"
    echo "In region... ${REGION}"

    cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: kindest/node:${CLUSTER_VERSION}
  kubeadmConfigPatches:
  labels:
    topology.kubernetes.io/region: ${REGION}
    topology.kubernetes.io/zone: ${REGION}-a
- role: worker
  image: kindest/node:${CLUSTER_VERSION}
  kubeadmConfigPatches:
  labels:
    topology.kubernetes.io/region: ${REGION}
    topology.kubernetes.io/zone: ${REGION}-a
- role: worker
  image: kindest/node:${CLUSTER_VERSION}
  kubeadmConfigPatches:
  labels:
    topology.kubernetes.io/region: ${REGION}
    topology.kubernetes.io/zone: ${REGION}-a
EOF

    # Create cluster
    kind create cluster --name="${CN}" --config=kind-config.yaml
    
    # Clean up config file
    rm kind-config.yaml
}

# Execute the setup function with provided arguments
# kcc dymium v1.33.1 us-gov-west-1

#!/usr/bin/env bash

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

cat <<-EOF > kind-config.yaml
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
    kind create cluster --name="${CN}" --config=kind-config.yaml && echo "Successfully created ${CN}" || return;
    kubectl config rename-context kind-${CN} ${CN}
    
    # Clean up config file
    rm kind-config.yaml

    # Install Cilium and Metallb
    install_cilium "$CN"
    install_metallb "$CN"
    
    # Zarf init
    zarf package deploy oci://ghcr.io/zarf-dev/packages/init:v0.54.0 --confirm
}

# Function to install cilium
install_cilium() {
    local CN=$1

    # Install Cilium
    helm repo add cilium https://helm.cilium.io/
    helm repo update
    VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/cilium/cilium/releases/latest)
    CILIUM_VERSION=${VERSION##*/}
    CILIUM_SHA_TAG="sha256:bfeb3f1034282444ae8c498dca94044df2b9c9c8e7ac678e0b43c849f0b31746"

    docker pull quay.io/cilium/cilium:$CILIUM_VERSION
    kind load docker-image quay.io/cilium/cilium:$CILIUM_VERSION

    helm install cilium cilium/cilium --version $CILIUM_VERSION \
      --namespace kube-system \
      --set image.pullPolicy=IfNotPresent \
      --set ipam.mode=kubernetes
   
    mkdir -p ~/bin
    FILE=~/bin/cilium
    if [ ! -f "$FILE" ]; then
      VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/cilium/cilium-cli/releases/latest)
      CILIUM_CLI_VERSION=${VERSION##*/}
      CLI_ARCH=amd64
      if [ "$(uname -m)" = "arm64" ]; then CLI_ARCH=arm64; fi
      curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-darwin-${CLI_ARCH}.tar.gz{,.sha256sum}
      shasum -a 256 -c cilium-darwin-${CLI_ARCH}.tar.gz.sha256sum
      tar xzvfC cilium-darwin-${CLI_ARCH}.tar.gz ~/bin
      rm cilium-darwin-${CLI_ARCH}.tar.gz{,.sha256sum}
    fi

    echo "Check cilium status"
    cilium status --wait --context ${CN}
}

# Function to install metallb
install_metallb() {
    local CN=$1
    
    # Inspect the Docker network
    OCTET=$(docker network inspect -f '{{.IPAM.Config}}' kind | sed 's/.*[0-9][0-9][0-9]\.\([0-9][0-9]\)\..*/\1/')

    # Install Metallb
    METALLB_VERSION="0.14.9"
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$METALLB_VERSION/config/manifests/metallb-native.yaml --context ${CN}
    kubectl --context ${CN} wait --for=condition=Ready  pod -l app=metallb -n metallb-system --timeout=120s

    echo "Adding IPPool..."

cat <<EOF | kubectl apply --context ${CN} -f -
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.${OCTET}.255.1-172.${OCTET}.255.25  
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ip-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - ip-pool
EOF
}

# Main execution
kind_setup dymium v1.33.1 us-gov-west-1

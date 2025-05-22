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

    # Check for supporting commands
    echo "Verifying prerequisites"
    APPS=(
      docker
      helm
      kind
      kubectl
      tar
    )
    NOTIFY=0
    for i in "${APPS[@]}"; do
      if ! command -v $i &> /dev/null; then
          printf '\e[0;31m\u2718 '$i'\e[0m\n'
          NOTIFY=1
      else
          printf '\e[0;32m\u2714 '$i'\e[0m\n'
      fi
    done
    [[ NOTIFY -eq 1 ]] && (echo "Please install the required commands"; return)
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
    kind create cluster --name="${CN}" --config=kind-config.yaml && printf '\e[0;32m\u2714 'Successfully created $CN'\e[0m\n' || return;
    # kubectl config rename-context kind-${CN} ${CN}
    
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
    
    # Default OS
    OS=darwin
    case $OSTYPE in
        linux-gnu*) OS=linux ;;
        darwin*) OS=darwin ;;
    esac

    printf '\e[0;32m\u2714 'OS=$OS'\e[0m\n'

    CILIUM_VERSION=${VERSION##*/}

    docker pull quay.io/cilium/cilium:$CILIUM_VERSION

    helm install cilium cilium/cilium --version $CILIUM_VERSION \
      --namespace kube-system \
      --set image.pullPolicy=IfNotPresent \
      --set ipam.mode=kubernetes
    printf '\e[0;32m\u2714 'Installed cilium'\e[0m\n'
    LOCAL_BIN=~/.local/bin
    FILE=${LOCAL_BIN}/cilium
    if [ ! -f "$FILE" ]; then
        mkdir -p ${LOCAL_BIN}
        VERSION=$(curl -Ls -o /dev/null -w %{url_effective} https://github.com/cilium/cilium-cli/releases/latest)
        CILIUM_CLI_VERSION=${VERSION##*/}
        echo "Downloading cilium CLI version $CILIUM_CLI_VERSION..."

        # Default
        CLI_ARCH=arm64
        case $(uname -m) in
          aarch64) CLI_ARCH=amd64 ;;
          x86_64) CLI_ARCH=amd64 ;;
          amd64) CLI_ARCH=arm64 ;;
          arm64) CLI_ARCH=arm64 ;;
        esac
        printf '\e[0;32m 'Downloading cilium-$OS-$CLI_ARCH.tar.gz'\e[0m\n'
        curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
        shasum -a 256 -c cilium-${OS}-${CLI_ARCH}.tar.gz.sha256sum
        tar xzvfC cilium-${OS}-${CLI_ARCH}.tar.gz $LOCAL_BIN
        rm cilium-${OS}-${CLI_ARCH}.tar.gz{,.sha256sum}
    fi

    printf '\e[0;32m 'Check cilium status...'\e[0m\n'
    $LOCAL_BIN/cilium status --wait --context ${CN}
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

    printf '\e[0;32m 'Adding IPPool...'\e[0m\n'

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

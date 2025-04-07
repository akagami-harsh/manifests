#!/bin/bash
set -e

error_exit() {
    echo "Error occurred in script at line: ${1}."
    exit 1
}

trap 'error_exit $LINENO' ERR

# Check if a Kubernetes version is provided as an argument
K8S_VERSION=${1:-"v1.32.2"}
K8S_SHA256=""

# Map of known K8s versions to their SHA256 hashes
case "$K8S_VERSION" in
  "v1.32.2")
    K8S_SHA256="f226345927d7e348497136874b6d207e0b32cc52154ad8323129352923a3142f"
    ;;
  "v1.31.6")
    K8S_SHA256="28b7cbb993dfe093c76641a0c95807637213c9109b761f1d422c2400e22b8e87"
    ;;
  "v1.30.10")
    K8S_SHA256="4de75d0e82481ea846c0ed1de86328d821c1e6a6a91ac37bf804e5313670e507"
    ;;
  "v1.29.14")
    K8S_SHA256="8703bd94ee24e51b778d5556ae310c6c0fa67d761fae6379c8e0bb480e6fea29"
    ;;
  *)
    echo "Warning: SHA256 hash not found for version $K8S_VERSION. Using version without SHA256 verification."
    ;;
esac

echo "Install KinD..."
sudo swapoff -a

# This conditional helps running GH Workflows through
# [act](https://github.com/nektos/act)
if [ -e /swapfile ]; then
    sudo rm -f /swapfile
    sudo mkdir -p /tmp/etcd
    sudo mount -t tmpfs tmpfs /tmp/etcd
fi

{
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv kind /usr/local/bin
} || { echo "Failed to install KinD"; exit 1; }


echo "Creating KinD cluster with Kubernetes version $K8S_VERSION ..."

NODE_IMAGE="kindest/node:$K8S_VERSION"
if [ -n "$K8S_SHA256" ]; then
  NODE_IMAGE="$NODE_IMAGE@sha256:$K8S_SHA256"
fi

echo "Using node image: $NODE_IMAGE"

echo "
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
# Configure registry for KinD.
containerdConfigPatches:
- |-
  [plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"REGISTRY_NAME:REGISTRY_PORT\"]
    endpoint = [\"http://REGISTRY_NAME:REGISTRY_PORT\"]
# This is needed in order to support projected volumes with service account tokens.
# See: https://kubernetes.slack.com/archives/CEKK1KTN2/p1600268272383600
kubeadmConfigPatches:
  - |
    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterConfiguration
    metadata:
      name: config
    apiServer:
      extraArgs:
        \"service-account-issuer\": \"https://kubernetes.default.svc\"
        \"service-account-signing-key-file\": \"/etc/kubernetes/pki/sa.key\"
nodes:
- role: control-plane
  image: $NODE_IMAGE
- role: worker
  image: $NODE_IMAGE
- role: worker
  image: $NODE_IMAGE
" | kind create cluster --config -


echo "Install Kustomize ..."
{
    curl --silent --location --remote-name "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.3/kustomize_v5.4.3_linux_amd64.tar.gz"
    tar -xzvf kustomize_v5.4.3_linux_amd64.tar.gz
    chmod a+x kustomize
    sudo mv kustomize /usr/local/bin/kustomize
} || { echo "Failed to install Kustomize"; exit 1; }

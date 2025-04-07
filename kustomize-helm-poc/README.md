# Kubeflow Helm Migration POC

This repository contains a Proof of Concept (POC) for migrating Kubeflow components from Kustomize to Helm charts. The POC demonstrates a hybrid approach that allows for incremental migration while maintaining backward compatibility.

## Overview

This POC focuses on the Training Operator component, showing how it can be packaged as a Helm chart while preserving existing Kustomize overlay functionality. This approach provides users with two deployment options:

1. **Direct Helm installation** (`helm install training-operator ./charts/training-operator`)
2. **Kustomize with Helm support** (`kustomize build --enable-helm ./overlay/kubeflow`)

## Directory Structure

```
helm-poc/
├── base/                      # Kustomize base configuration using Helm charts
│   └── kustomization.yaml     # References Helm chart for Training Operator
├── charts/                    # Helm charts repository
│   └── training-operator/     # Training Operator Helm chart
│       ├── Chart.yaml         # Chart metadata
│       ├── values.yaml        # Default configuration values
│       ├── templates/         # Kubernetes manifest templates
│       │   ├── deployment.yaml
│       │   ├── rbac.yaml
│       │   ├── service.yaml
│       │   └── serviceaccount.yaml
│       └── crds/              # Custom Resource Definitions
├── overlay/                   # Kustomize overlays for different environments
│   └── kubeflow/              # Kubeflow-specific overlay
│       └── kustomization.yaml # Extends base with Kubeflow-specific settings
├── run-kustomize.sh          # Helper script to run Kustomize build
└── kustomize-helper.sh       # Additional helper script for kustomize commands
```

## Usage

### Option 1: Deploying with Kustomize and Helm Support

```bash
./run-kustomize.sh
```

This will generate the complete Kubernetes manifests by:

To apply directly to your cluster: **This may not work yet**

```bash
./run-kustomize.sh | kubectl apply -f -
```

### Option 2: Deploying with Helm Directly

To install the Training Operator using Helm directly:

```bash
helm install training-operator ./charts/training-operator \
  --namespace kubeflow \
  --create-namespace
```

## Implementation Details

### Base Configuration

The base configuration uses Kustomize's Helm support to reference the Training Operator chart:

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

helmGlobals:
  chartHome: ../charts

helmCharts:
- name: training-operator
  includeCRDs: true
  valuesInline:
    rbac:
      create: true
    namespace: kubeflow
    # ... additional values
```

### Overlay Configuration

The overlay extends the base configuration with environment-specific settings:

```yaml
# overlay/kubeflow/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: kubeflow
resources:
  - ../../base
images:
  - name: ghcr.io/kubeflow/training-v1/training-operator
    newTag: v1-5c0e763
# ... additional configurations
```

## Troubleshooting

### Path Resolution Issues

If you encounter path resolution errors, ensure you're using the `--load-restrictor LoadRestrictionsNone` flag with Kustomize:

```bash
kustomize build --enable-helm --load-restrictor LoadRestrictionsNone ./overlay/kubeflow
```

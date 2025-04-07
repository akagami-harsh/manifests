# Training Operator Helm Chart

This Helm chart installs the Kubeflow Training Operator

## Introduction

The Kubeflow Training Operator provides Kubernetes custom resources that make it easy to run distributed or non-distributed training jobs for machine learning frameworks on Kubernetes.

This chart bootstraps a Training Operator deployment on a Kubernetes cluster using the Helm package manager.

## Installing the Chart

To install the chart with the release name `training-operator`:

```bash
helm install training-operator kubeflow/training-operator
```

The command deploys the Training Operator on the Kubernetes cluster with the default configuration. The [Parameters](#parameters) section lists the parameters that can be configured during installation.

## Parameters

The following table lists the configurable parameters of the Training Operator chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `nameOverride` | Provide a name in place of training-operator | `""` |
| `fullnameOverride` | Provide a name to substitute for the full name | `""` |
| `namespace` | Namespace for the training operator installation | `""` (uses release namespace) |
| `image.repository` | Training operator image repository | `kubeflow/training-operator` |
| `image.tag` | Training operator image tag | `latest` |
| `image.pullPolicy` | Training operator image pull policy | `IfNotPresent` |
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.annotations` | Additional annotations for the service | `{}` |
| `resources.limits.cpu` | CPU limits for the training operator | `500m` |
| `resources.limits.memory` | Memory limits for the training operator | `512Mi` |
| `resources.requests.cpu` | CPU requests for the training operator | `100m` |
| `resources.requests.memory` | Memory requests for the training operator | `256Mi` |
| `annotations` | Annotations to apply to all resources | `{}` |
| `labels` | Labels to apply to all resources | `{}` |
| `securityContext` | Security context for the pod | `{ runAsUser: 1000, runAsGroup: 1000, fsGroup: 1000 }` |
| `serviceAccount.create` | Specifies whether a service account should be created | `true` |
| `serviceAccount.name` | The name of the service account to use | `""` |
| `serviceAccount.annotations` | Annotations to add to the service account | `{}` |
| `rbac.create` | Specifies whether RBAC resources should be created | `true` |
| `crds.create` | Specifies whether CRDs should be created | `true` |
| `crds.apiVersion` | API version of the CRDs | `kubeflow.org/v1` |
| `crds.kinds` | List of CRD kinds to create | `[TFJob, PyTorchJob, MXNetJob, XGBoostJob, MPIJob]` |
| `healthProbe.livenessProbe` | Liveness probe configuration | See values.yaml |
| `healthProbe.readinessProbe` | Readiness probe configuration | See values.yaml |
| `nodeSelector` | Node labels for pod assignment | `{}` |
| `tolerations` | Tolerations for pod assignment | `[]` |
| `affinity` | Affinity for pod assignment | `{}` |

## Usage

Once the Training Operator is installed, you can create training jobs using the custom resources:

### Example TFJob

```yaml
apiVersion: kubeflow.org/v1
kind: TFJob
metadata:
  name: mnist
spec:
  tfReplicaSpecs:
    PS:
      replicas: 1
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: tensorflow
            image: kubeflow/tf-mnist-with-summaries:latest
            command:
              - python
              - /var/tf_mnist/mnist_with_summaries.py
            env:
              - name: TF_CONFIG
                valueFrom:
                  configMapKeyRef:
                    name: mnist-map
                    key: tf-config-ps
    Worker:
      replicas: 2
      restartPolicy: OnFailure
      template:
        spec:
          containers:
          - name: tensorflow
            image: kubeflow/tf-mnist-with-summaries:latest
            command:
              - python
              - /var/tf_mnist/mnist_with_summaries.py
            env:
              - name: TF_CONFIG
                valueFrom:
                  configMapKeyRef:
                    name: mnist-map
                    key: tf-config-worker
```

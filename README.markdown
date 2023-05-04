# KubeECR

KubeECR is a script that can fetch a new AWS ECR token and inject it into an existing Kubernetes docker-registry secret.

Using ECR from outside of AWS hosting requires logging in, as many private docker registries do, however the login credentials only last 12 hours.
In Kubernetes, docker registry credentials are kept in long-lived secrets that are referred to, and perhaps managed by, other resources.
These two patterns do not mix well.

The obvious solution is to regularly run a script to update the credentials.
Many such examples exist online however they typically want to have the secret name preconfigured, then delete and recreate that secret to renew it.
While these examples will work, they don't follow typical kubernetes design patterns.

KubeECR is different.
Rather than specify the secret to create, then continually recreate it, KubeECR looks for existing secrets with an annotation.
Those secrets are then updated in-place.
In this way, all existing Kubernetes tooling, including for example common deployment mechanisms or visualisations that rely on parent references, continue to work.
Meanwhile the secrets declare themselves as needing updating rather than changing the updater config.
Users of cert-manager will recognize this as similar to how an ingress can declare that it needs a certificate generated.

## Installation

Though KubeECR can be run as a script exteranl to a kubernetes cluster, it is typically going to be run as a CronJob.
Installation can be as simple as running the kustomization files Included in the `manifests/` directory.
This installation creates the RBAC needed to monitor and update the secerets.
It requires a secret called `kubeecr-aws-secrets` containing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` in the same namespace as the CronJob; these are used to request the login password from aws.

Users may wish to add their own changes to the kustomization, examples of doing so can be seen in the `examples/installation/kustomization.yaml`.
That example shows how to create the necessary secret as well.

## Usage

During installation, you should have setup the AWS access, however it does not contain the information about the ECR registry to be logged into.
This is contained within the annotations on the secrets themselves.

To configure a secret to be updated by KubeECR, add the annotation `deft.com/kubeecr` whose value is the account number and region combined with a `/`.
For example:

```yaml
metadata:
  annotations:
    deft.com/kubeecr: 123456789/us-west-2
```

A usage example can be seen in `examples/usage/`, which contains a dummy application and its imagePullSecrets which contains the annotation.

# Thanks

Work on KubeECR was sponsored by [Deft](deft.com) (formerly ServerCentral).
Deft provides AWS consulting, server colocation, and other managed services.

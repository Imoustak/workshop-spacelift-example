# workshop

Infrastructure behind the EKS workshop — a VPC, an EKS Auto Mode cluster, and the
ACK, kro and Argo CD capabilities running on top of it.

Everything is OpenTofu and Spacelift applies it, so most of the time you won't be
running `tofu` yourself. You'll edit a variable, push, and let the stack do the
rest.

| | |
| --- | --- |
| Region | `eu-west-1` |
| Cluster | `workshop` |
| Space | `workshop` |

## Layout

| Path | What lives there |
| --- | --- |
| `aws/networking/` | VPC, subnets, NAT, routing |
| `aws/eks/` | The cluster and its capabilities |
| `spacelift/` | The Spacelift space and the stack definitions |

## Configuration

If you're forking this, four variables still point at the environment it was built
in and won't work anywhere else. They're marked in the code, so you can find them
with:

```bash
grep -rn "CHANGE ME" .
```

| Variable | Where | What it is |
| --- | --- | --- |
| `aws_integration_id` | `spacelift/variables.tf` | The Spacelift AWS integration the stacks assume |
| `vcs` | `spacelift/variables.tf` | Your VCS namespace and integration |
| `cluster_admin_principal_arns` | `aws/eks/variables.tf` | IAM principals that get cluster admin |
| `argocd_admin_user_names` | `aws/eks/variables.tf` | Identity Center users that get Argo CD ADMIN |

Edit the defaults directly, or leave them alone and override per stack in Spacelift
with `TF_VAR_<name>`. If you go the environment variable route, the list and object
values need to parse as HCL — brackets and braces included:

```bash
TF_VAR_cluster_admin_principal_arns='["arn:aws:iam::<account-id>:user/<you>"]'
TF_VAR_vcs='{type="GITHUB",enterprise=true,namespace="<your-org>",id="<vcs-integration-id>"}'
```

Everything else — region, cluster name, CIDR, Kubernetes version — has a sensible
default in the `variables.tf` next to each stack.

## How changes get applied

There are two stacks in the `workshop` space:

| Stack | Tracks |
| --- | --- |
| `networking` | `aws/networking` |
| `kubernetes` | `aws/eks` |

`kubernetes` depends on `networking` and pulls the VPC and subnet IDs straight out
of its outputs, so that's one piece of wiring you can forget about.

Both track `main` with auto-deploy on. Push and the affected stack plans and
applies on its own — there's no confirmation step waiting for you. If you'd rather
see the plan first, open a pull request instead; that gives you a proposed run and
leaves the tracked stack alone.

Changes under `spacelift/` are applied by the `workshop-admin` stack, so adding a
new stack works the same way as everything else.

## Getting access to the cluster

Your IAM principal needs an access entry before `kubectl` will work. Add it to
`cluster_admin_principal_arns` in `aws/eks/variables.tf` and push — the cluster is
API-auth only, so there's no `aws-auth` ConfigMap to go hunting for.

Once that lands:

```bash
aws eks update-kubeconfig --region eu-west-1 --name workshop
kubectl get ns
```

If `kubectl get nodes` comes back empty, nothing is wrong. Auto Mode scales from
zero and will bring up a node as soon as something needs to be scheduled.

## Argo CD

You can reach the UI from the Capabilities tab of the cluster in the EKS console,
or grab the URL directly:

```bash
kubectl get capability argocd -o jsonpath='{.status.serverUrl}'
```

Sign in with IAM Identity Center. There's no local admin account and no
`argocd-rbac-cm` to edit — who gets in is decided entirely by the capability's
role mapping.

To give someone the ADMIN role, add their Identity Center user name here:

```hcl
# aws/eks/variables.tf
argocd_admin_user_names = ["your-idc-user", "a-colleague"]
```

They need to already exist as a user in the Identity Center directory, since this
repo doesn't create people. Pushing adds them to the `argocd-admins` group, which
is what ADMIN is mapped to. The Identity Center application assignment sorts
itself out, so leave that alone.

## ACK

The controllers run on AWS-managed infrastructure — there's nothing to install and
you won't see any pods for it in the cluster. The CRDs are already registered, so
you can go straight to creating AWS resources through Kubernetes:

```yaml
apiVersion: s3.services.k8s.aws/v1alpha1
kind: Bucket
metadata:
  name: demo
  namespace: default
spec:
  name: workshop-demo-<your-suffix>
```

Bucket names are globally unique, so pick something specific to you. Then watch it
settle:

```bash
kubectl describe bucket demo
```

A couple of things worth knowing:

- Deleting the Kubernetes object deletes the real AWS resource. If that's not what
  you want, add the `services.k8s.aws/deletion-policy: retain` annotation.
- To adopt something that already exists rather than create it fresh, use
  `services.k8s.aws/adoption-policy: adopt-or-create`.

## kro

kro lets you bundle several resources behind a single custom API. It's a two-step
thing, which is the part that usually trips people up the first time.

### 1. Define the API

Applying a ResourceGraphDefinition doesn't create anything in AWS. It defines a new
type and registers it with the cluster:

```yaml
apiVersion: kro.run/v1alpha1
kind: ResourceGraphDefinition
metadata:
  name: simple-bucket
spec:
  schema:
    apiVersion: v1alpha1
    kind: SimpleBucket
    spec:
      name: string
  resources:
    - id: bucket
      template:
        apiVersion: s3.services.k8s.aws/v1alpha1
        kind: Bucket
        metadata:
          name: ${schema.spec.name}
        spec:
          name: ${schema.spec.name}
```

Check it registered before going further:

```bash
kubectl get rgd
kubectl api-resources | grep SimpleBucket
```

### 2. Create an instance

This is the step that actually builds something:

```yaml
apiVersion: kro.run/v1alpha1
kind: SimpleBucket
metadata:
  name: my-bucket
  namespace: default
spec:
  name: workshop-kro-<your-suffix>
```

Now the underlying `Bucket` appears, and the S3 bucket behind it. Delete the
`SimpleBucket` and everything it created goes with it.

The example above is deliberately tiny. The reason kro is interesting is that a
graph can hold several resources at once, and it works out the ordering and passes
values between them for you — a bucket plus a queue plus the notification wiring,
all from one small custom resource.

If an instance gets accepted but nothing shows up underneath it, that's usually kro
lacking permission for the kinds in the graph. `kro_access_policy_arn` in
`aws/eks/variables.tf` is the knob for that.

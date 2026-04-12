# nixery-helm

Helm chart for [Nixery](https://github.com/tazjin/nixery): a registry that builds container images from Nix on demand. Wire it up with object storage if you want more than one replica, because layers need to live somewhere everyone can read.

Chart defaults point at a Nixery image on GHCR and port `8080`. CI still uses [`charts/nixery/ci/ci-values.yaml`](charts/nixery/ci/ci-values.yaml) with Docker Distribution for Kind.

> [!CAUTION]
> This chart’s defaults assume a **privileged** container, **unconfined seccomp**, and permissive Nix settings so on-demand image builds work. That makes the pod **high-trust on the node**. For production or shared clusters, use **strong isolation** appropriate to your threat model—for example set **`runtimeClassName`** to a **`RuntimeClass`** such as [Kata Containers](https://katacontainers.io/), run on dedicated nodes, or combine with policy and other controls.

## Quickstart

From a clone of this repo:

```bash
helm upgrade --install nixery ./charts/nixery \
  --namespace nixery --create-namespace \
  --set image.repository=YOUR_REGISTRY/nixery \
  --set image.tag=YOUR_TAG \
  --set service.port=8080 \
  --set storage.backend=s3 \
  --set storage.s3.bucket=YOUR_BUCKET \
  --set storage.s3.region=us-east-1 \
  --set storage.s3.existingSecret=YOUR_S3_CREDENTIALS_SECRET \
  --set replicaCount=2
```

Create the Kubernetes secret first if you use `storage.s3.existingSecret`; keys default to `access-key-id` and `secret-access-key` (override with `storage.s3.accessKeyKey` / `secretKeyKey` if yours differ). On AWS you can skip static keys and use IRSA instead: annotate the service account (`serviceAccount.annotations`) with the role ARN and leave the secret empty.

From GHCR (Helm 3.8+):

```bash
helm upgrade --install nixery oci://ghcr.io/builderhub/nixery-helm/nixery \
  --version X.Y.Z \
  --namespace nixery --create-namespace \
  -f your-values.yaml
```

## Values reference

These are the knobs people actually touch. See [`charts/nixery/values.yaml`](charts/nixery/values.yaml) for the full file and defaults.

| Key | What it does |
|-----|----------------|
| `replicaCount` | Pod count. Use `1` with `filesystem` storage; use `2+` only with `s3` or `gcs` so layers are shared. |
| `image.repository` | Container image (default `ghcr.io/builderhub/nixery-helm/nixery`; override for your registry). |
| `image.tag` | Image tag. |
| `image.pullPolicy` | Kubernetes pull policy. |
| `imagePullSecrets` | Pull secrets for private registries. |
| `nameOverride` / `fullnameOverride` | Shorten or fix Kubernetes resource names. |
| `serviceAccount.create` | Create a dedicated ServiceAccount. |
| `serviceAccount.name` | Fixed SA name when `create` is true. |
| `serviceAccount.annotations` | e.g. EKS IRSA `eks.amazonaws.com/role-arn`. |
| `serviceAccount.automountServiceAccountToken` | Whether to mount the API token. |
| `podAnnotations` | Extra pod annotations. |
| `podSecurityContext` | Pod-level `securityContext`. |
| `securityContext` | Container-level `securityContext`. |
| `runtimeClassName` | Pod `runtimeClassName` (e.g. Kata) for VM or alternate runtime isolation; cluster must define the `RuntimeClass`. |
| `service.type` | `ClusterIP`, `NodePort`, `LoadBalancer`, etc. |
| `service.port` | Service port and `PORT` env (must match what the process listens on). |
| `service.annotations` | Service annotations (e.g. cloud LB hints). |
| `ingress.enabled` | Turn on an Ingress. |
| `ingress.className` | IngressClass name. |
| `ingress.annotations` / `hosts` / `tls` | Standard Ingress wiring. |
| `resources` | CPU/memory requests and limits. |
| `nodeSelector` / `tolerations` / `affinity` / `topologySpreadConstraints` | Scheduling. |
| `podDisruptionBudget.enabled` | Create a PDB when it makes sense (`replicaCount > 1`). |
| `podDisruptionBudget.minAvailable` | PDB `minAvailable`. |
| `autoscaling.*` | Optional HPA (needs at least one of CPU or memory target). |
| `nixery.channel` | `NIXERY_CHANNEL` — Nixpkgs channel or pinned commit string. |
| `nixery.pkgsRepo` | `NIXERY_PKGS_REPO` — git URL for a custom package set (only one of channel / repo / path). |
| `nixery.pkgsPath` | `NIXERY_PKGS_PATH` — local path inside the image (unusual in Kubernetes). |
| `nixery.timeout` | `NIX_TIMEOUT` (seconds per Nix build). |
| `nixery.popularityUrl` | `NIX_POPULARITY_URL` if you use popularity data. |
| `nixery.extraEnv` | Extra `env` entries (list of name/value or valueFrom maps). |
| `storage.backend` | `filesystem`, `s3`, or `gcs`. |
| `storage.s3.bucket` | Required for S3. |
| `storage.s3.endpoint` | Non-AWS S3-compatible endpoint (optional). |
| `storage.s3.region` | AWS region or equivalent (optional). |
| `storage.s3.existingSecret` | Secret holding access key / secret key. |
| `storage.s3.accessKeyKey` / `secretKeyKey` | Keys inside that secret. |
| `storage.s3.createSecret` | Chart creates a Secret from `accessKey` / `secretKey` (dev only). |
| `storage.gcs.bucket` | GCS bucket name. |
| `storage.gcs.existingSecret` | Secret with GCP JSON key; mounted and `GOOGLE_APPLICATION_CREDENTIALS` set. |
| `storage.gcs.credentialsKey` / `mountPath` | Filename and mount path for the key file. |
| `storage.filesystem.storagePath` | `STORAGE_PATH` on disk. |
| `storage.filesystem.emptyDir` | Ephemeral volume for that path. |
| `storage.filesystem.persistence` | PVC for that path (`existingClaim` or dynamic PVC). |
| `tmp.emptyDir` | Extra scratch under `/tmp` for builds. |
| `extraVolumes` / `extraVolumeMounts` | Attach arbitrary volumes. |
| `extraEnvFrom` | Extra `envFrom` (e.g. ConfigMaps). |

## License

MIT — see [LICENSE](LICENSE).

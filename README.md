# ClusterAPI - CAPMOX + Talos
Declarative Kubernetes clusters on Proxmox using Cluster API, CAPMOX provider, and Talos Linux.

## Architecture
- **Terraform** creates a single-node Talos "management cluster" directly on Proxmox. This VM runs the Cluster API controllers.
- **Cluster API** manages workload clusters declaratively — control planes, workers, GPU nodes, Cilium CNI, andautoscaling — all from YAML manifests applied to the management cluster.

## Quick start

### 1. Proxmox user/token
```shell
pveum user add capmox@pve
pveum user token add capmox@pve capi --privsep 1
pveum role add CAPMOX -privs "Sys.Audit,Pool.Audit,VM.Audit,VM.Allocate,VM.Clone,VM.Config.CPU,VM.Config.Memory,VM.Config.Disk,VM.Config.Network,VM.Config.CDROM,VM.Config.Cloudinit,VM.Config.Options,VM.Config.HWType,VM.PowerMgmt,VM.Migrate,Datastore.Audit,Datastore.AllocateSpace,SDN.Audit,SDN.Use"
pveum aclmod / --users capmox@pve --roles CAPMOX
pveum aclmod / --tokens "capmox@pve!capi" --roles CAPMOX
```

### 2. Prepare terraform variables
```shell
cd terraform
cp mgmt.tfvars.example mgmt.tfvars && cp mgmt.config.example mgmt.config
```

### 3. Create the management cluster
```shell
terraform init -backend-config=mgmt.config
terraform apply -var-file=mgmt.tfvars
terraform output -raw kubeconfig > mgmt
```

### 4. Configure ~/.cluster-api/clusterctl.yaml
```yaml
PROXMOX_URL: "https://<proxmox-ip>:8006"
PROXMOX_TOKEN: "capmox@pve!capi"
PROXMOX_SECRET: "<your-token-secret>"
providers:
  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-bootstrap-provider-talos/releases/v0.6.11/bootstrap-components.yaml"
    type: "BootstrapProvider"

  - name: "talos"
    url: "https://github.com/siderolabs/cluster-api-control-plane-provider-talos/releases/v0.5.12/control-plane-components.yaml"
    type: "ControlPlaneProvider"

  - name: "proxmox"
    url: "https://github.com/ionos-cloud/cluster-api-provider-proxmox/releases/v0.8.1/infrastructure-components.yaml"
    type: "InfrastructureProvider"
```

### 5. Initialize CAPI providers and create a workload cluster
In management context:
```shell
clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos --addon helm
kubectl apply -f example-cluster.yaml
clusterctl describe cluster example-cluster
clusterctl get kubeconfig example-cluster > example
```

### 6. Cilium
Set `cilium: enabled` label on cluster kind and apply the HelmChartProxy:

```shell
kubectl apply -f resources/cni.yaml
```

### 7. Autoscaler
Edit resources/autoscaler.yaml - set clusterName.

```shell
kubectl apply -f resources/autoscaler-rbac.yaml
helm install autoscaler autoscaler/cluster-autoscaler \
  -f resources/autoscaler.yaml -n default
```

### GPU
For GPU-accelerated workloads:

- Terraform creates an additional Talos VM template with a custom factory image (NVIDIA drivers baked in via system extensions).
- Apply `example-gpu-worker.yaml` — it defines a ProxmoxMachineTemplate referencing the GPU template (ID 1001), a TalosConfigTemplate with NVIDIA kernel modules and a taint nvidia.com/gpu: NoSchedule, and a MachineDeployment.
- Apply `resources/gpu-operator.yaml` — a HelmChartProxy that deploys the NVIDIA GPU Operator via the Cluster API addon mechanism.


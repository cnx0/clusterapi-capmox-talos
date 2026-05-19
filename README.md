# ClusterAPI - CAPMOX + Talos

## Create Talos template and management cluster
```shell
cd terraform
terraform init -backend-config=mgmt.config
terraform apply -var-file=mgmt.tfvars
terraform output -raw kubeconfig > mgmt
```

## Create user/token
```shell
pveum user add capmox@pve
pveum user token add capmox@pve capi --privsep 1
pveum role add CAPMOX -privs "Sys.Audit,Pool.Audit,VM.Audit,VM.Allocate,VM.Clone,VM.Config.CPU,VM.Config.Memory,VM.Config.Disk,VM.Config.Network,VM.Config.CDROM,VM.Config.Cloudinit,VM.Config.Options,VM.Config.HWType,VM.PowerMgmt,VM.Migrate,Datastore.Audit,Datastore.AllocateSpace,SDN.Audit,SDN.Use"
pveum aclmod / --users capmox@pve --roles CAPMOX
pveum aclmod / --tokens "capmox@pve!capi" --roles CAPMOX
```

## ~/.cluster-api/clusterctl.yaml
```yaml
PROXMOX_URL: "https://100.64.100.100:8006"
PROXMOX_TOKEN: "capmox@pve!capi"
PROXMOX_SECRET: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
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

## Init and create cluster
In management context:
```shell
clusterctl init --infrastructure proxmox --ipam in-cluster --control-plane talos --bootstrap talos --addon helm
kubectl apply -f example-cluster.yaml
clusterctl describe cluster example-cluster
clusterctl get kubeconfig example-cluster > example
```

## Install Cilium
Set label in cluster manifest to `cilium: enblaed` and apply `cni.yaml`.
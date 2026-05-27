variable "pve" {
  type = object({
    endpoint          = string
    api_token         = string
    username          = string
    private_key       = string
    node_name         = string
    vm_id             = string
    template_vm_id    = number
    storage_disks     = string
    storage_cloudinit = string
    storage_efi       = string
    cp_mem            = number
    dns_domain        = string
    dns_server        = string
    vlan_id           = number
    gateway           = string
    gpu               = bool
    gpu_name          = string
  })

  default = {
    endpoint          = ""
    api_token         = ""
    username          = ""
    private_key       = ""
    node_name         = ""
    vm_id             = ""
    template_vm_id    = 1000
    storage_disks     = ""
    storage_cloudinit = ""
    storage_efi       = ""
    cp_mem            = 4096
    dns_domain        = ""
    dns_server        = ""
    vlan_id           = 0
    gateway           = ""
    gpu               = false
    gpu_name          = ""
  }
}

variable "talos" {
  type = object({
    cluster_name = string
    vm_name      = string
    cp_ip        = string
    vip          = string
    version      = string
  })
}

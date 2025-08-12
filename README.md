
<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/d9a77d94-9ab6-4299-bbf2-1f93d4464037" />

```markdown
# Azure Infrastructure Demo (Bicep + Terraform) — Secure, No-Prompt Deploy

A small but realistic Azure lab that mixes **Bicep** (for a Windows VM stack) and **Terraform** (for foundational storage). It also includes hardened shell scripts that pass **secure parameters** without interactive prompts or leaking secrets in shell history.

---

## What this deploys

### With Bicep (`main.bicep`)
- **Windows Server VM** (default: 2022 Datacenter Azure Edition, `Standard_D2s_v5`)
- **Trusted Launch** security (Secure Boot + vTPM) and **Guest Attestation** extension
- **VNet/Subnet** (`10.0.0.0/16` → `10.0.0.0/24`)
- **NSG** with inbound **TCP 3389 (RDP)** allow rule *(⚠️ open to the internet by default)*
- **Public IP (Standard, Static)** with a DNS label
- **NIC** attached to the VM
- **Boot diagnostics** backed by a Storage Account
- **Data disk** (1023 GB) attached to the VM
- **Output:** `hostname` (FQDN from the Public IP)

> Params: `adminUsername` (string) and `adminPassword` (secure, min 12 chars)

### With Terraform (`main.tf`, `terraform.tf`)
- **Resource Group**: `example-resources` (default region: `East US`)
- **Storage Account**: `examplestoracc` (Standard/LRS)
- **Private Storage Container**: `content`

---

## Repo layout

```

main.bicep            # VM, networking, PIP, NSG, storage (boot diag), attestation
main.tf               # RG + Storage Account + Container via Terraform
terraform.tf          # Terraform required providers/versions
create-bicep.sh       # Legacy helper (kept for reference)
deploy.sh             # Bicep deploy helper (prompts for password or uses ADMIN\_PWD)
deploy\_fixed.sh       # Minimal Bicep deploy: JSON-parameter style, no prompt

````

---

## Prerequisites

- **Azure CLI** (`az`) and **Bicep** (comes with `az bicep`)
- **Terraform** ≥ 1.0
- An Azure subscription and permission to create resources

```bash
az login
az account set -s "<your-subscription-id>"
az bicep upgrade             # optional but recommended
terraform -version
````

---

## Quickstart

### 1) Deploy the VM stack with **Bicep** (no prompt)

**Option A — one-liner script (no prompts, safe for `!` in zsh):**

```bash
export ADMIN_PWD='YourStr0ng!Pass'
./deploy_fixed.sh
```

**Option B — interactive (prompts for password securely):**

```bash
./deploy.sh
# or provide ENV:
export ADMIN_PWD='YourStr0ng!Pass'
./deploy.sh
```

> Default resource group in these helpers is `dtmgroup` and template file is `main.bicep`. Adjust inside the scripts if needed.

**Get the VM’s FQDN (Bicep output):**

* The template outputs `hostname` (Public IP DNS). You can also view the Public IP resource in the portal once created.

---

### 2) Provision storage with **Terraform**

**Authenticate securely using your Azure CLI login** (no client secrets):

```bash
# Tell Terraform which subscription to use (no secrets)
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
# (Optional but nice)
export ARM_TENANT_ID=$(az account show --query tenantId -o tsv)

terraform init
terraform plan
terraform apply -auto-approve
```

> Note: `main.tf` uses `resource_provider_registrations = "none"` to avoid slow provider registrations. You can remove it if you want auto-registration.

---

## Architecture (high-level)

```
Resource Group (Bicep side)
├─ Virtual Network 10.0.0.0/16
│  └─ Subnet 10.0.0.0/24
│     └─ NSG: Allow TCP 3389 inbound  (⚠️ internet open by default)
├─ Public IP (Standard, Static) + DNS label
├─ NIC
├─ Windows VM (2022 Datacenter, D2s_v5)
│  ├─ Trusted Launch (Secure Boot + vTPM)
│  ├─ Guest Attestation extension
│  ├─ OS Disk (StandardSSD)
│  └─ Data Disk (1023 GB)
└─ Storage Account (boot diagnostics)

Resource Group (Terraform side)
└─ Storage Account (Standard/LRS)
   └─ Blob Container (private)
```

---

## Security notes (read me!)

* **Secure params (Bicep)**: The scripts avoid interactive `@secure()` prompts by passing values as JSON parameters or via temp files. This also prevents zsh `!` expansion issues.
* **Never commit secrets**: Don’t put passwords in Git or plain files.
* **RDP exposure**: The NSG allows TCP **3389** from `*`. For anything beyond a quick lab:

  * Restrict to your current public IP, or
  * Use Just-In-Time (JIT) VM access.
* **Terraform auth (local)**: Reuse your Azure CLI login with `ARM_SUBSCRIPTION_ID` env var; no client secret needed.
* **Terraform in CI**: Prefer **OIDC workload identity** (no secrets) or **Managed Identity** on an Azure agent. (Ask if you want a GitHub Actions/Azure DevOps snippet.)

---

## Cleanup

**Bicep resources (if deployed to `dtmgroup`):**

```bash
az group delete -n dtmgroup --yes --no-wait
```

**Terraform resources:**

```bash
terraform destroy -auto-approve
```

---

## Next steps

* Lock down the NSG to your IP or enable JIT.
* Move Terraform **state** to an Azure Storage backend (with CLI/MSI auth — no access keys).
* Add CI with OIDC to plan/apply automatically on PRs/merges.

---

```
```

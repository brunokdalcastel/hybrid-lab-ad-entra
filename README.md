# Hybrid Lab AD + Entra ID

Laboratório híbrido de identidade: **Active Directory on-premises** (Hyper-V) integrado com **Microsoft Entra ID** (Azure AD) via **Entra Connect**, provisionado com **Terraform**.

Projeto criado para portfólio, demonstrando competências em infraestrutura Windows Server, Active Directory, networking, Group Policy, Azure e Identity & Access Management (IAM).

## Arquitetura

```
On-Premises (Hyper-V)                          Azure (brazilsouth)
┌─────────────────────────────────┐            ┌───────────────────────────────┐
│  Internal vSwitch + NAT         │            │  rg-hybrid-lab                │
│  Subnet: 10.0.0.0/24           │            │                               │
│  Gateway: 10.0.0.2             │            │  ┌───────────────────────┐    │
│                                 │            │  │ vnet-hub-lab          │    │
│  ┌───────────┐  ┌───────────┐  │  (futuro)  │  │ 10.1.0.0/16          │    │
│  │  DC-01    │  │ CLIENT-01 │  │  VPN S2S   │  │  ┌─────────────────┐ │    │
│  │ .10       │  │ DHCP      │  │ ─────────► │  │  │ snet-default    │ │    │
│  │ Win 2019  │  │ Win 11    │  │            │  │  │ 10.1.1.0/24     │ │    │
│  │ AD/DNS/   │  │ Domain-   │  │            │  │  └─────────────────┘ │    │
│  │ DHCP/File │  │ joined    │  │            │  └───────────────────────┘    │
│  └───────────┘  └───────────┘  │            │  nsg-hub-lab                  │
│                                 │            │  rt-hub-lab                   │
│         ┌───────────┐          │            │  log-hybrid-lab               │
│         │  AADC     │          │            │                               │
│         │ (Fase 6)  │          │            └───────────────────────────────┘
│         └───────────┘          │
└─────────────────────────────────┘

Domínio AD: lab.brunocastel.com.br (NetBIOS: LAB)
Domínio Entra ID: brunocastel.com.br
```

## Fases do Projeto

### Fase 1 — Domain Controller e Serviços Base

Criação da VM **DC-01** no Hyper-V e configuração dos serviços fundamentais do Active Directory.

| Item | Detalhe |
|------|---------|
| VM | DC-01 — Windows Server 2019 |
| Rede | Internal vSwitch + NAT, IP fixo 10.0.0.10/24, gateway 10.0.0.2 |
| AD DS | Domínio `lab.brunocastel.com.br`, NetBIOS `LAB` |
| DNS | Integrado ao AD, zona `lab.brunocastel.com.br` |
| DHCP | Scope 10.0.0.100–10.0.0.200, options: DNS → 10.0.0.10, gateway → 10.0.0.2 |

**O que foi feito:**
- Instalação do Windows Server 2019 na VM Hyper-V
- Configuração de rede com Internal vSwitch e NAT para acesso à internet
- Promoção a Domain Controller com novo forest `lab.brunocastel.com.br`
- Configuração do DNS integrado ao AD
- Configuração do DHCP Server com scope e options

---

### Fase 2 — Estrutura Organizacional do AD

Criação da estrutura de OUs, grupos e usuários para simular um ambiente corporativo.

| Item | Detalhe |
|------|---------|
| OUs | Usuarios, Computadores, Servidores, Grupos, ServiceAccounts |
| Grupos | GRP-TI, GRP-RH, GRP-Financeiro (Security Groups, Global) |
| Usuários | 5 usuários de teste com UPN `@lab.brunocastel.com.br` |

**O que foi feito:**
- Criação de OUs organizadas por função
- Criação de Security Groups para cada departamento
- Criação de 5 usuários de teste distribuídos nos grupos
- Todos os usuários com UPN suffix `@lab.brunocastel.com.br`

---

### Fase 3 — File Server e Permissões NTFS

Configuração de compartilhamento de arquivos com permissões granulares por grupo.

| Item | Detalhe |
|------|---------|
| Share | `\\DC-01\Dados` |
| Estrutura | Pastas por departamento (TI, RH, Financeiro) |
| Permissões | NTFS permissions por Security Group |

**O que foi feito:**
- Habilitação do role File Server no DC-01
- Criação do compartilhamento `Dados` com subpastas por departamento
- Configuração de permissões NTFS granulares (cada grupo acessa apenas sua pasta)
- Remoção de herança e ajuste de ACLs

---

### Fase 4 — Estação de Trabalho, GPOs e Validação

Ingresso de estação Windows 11 ao domínio e criação de Group Policies para gerenciamento centralizado.

| Item | Detalhe |
|------|---------|
| VM | CLIENT-01 — Windows 11 Enterprise, DHCP |
| Domain Join | `lab.brunocastel.com.br` |
| Drive mapeado | `S:` → `\\DC-01\Dados` (via GPO) |

**GPOs criadas:**

| GPO | Escopo | Função |
|-----|--------|--------|
| MapaDrives | Usuarios | Mapeia drive S: para `\\DC-01\Dados` |
| AuditLogon | Domínio | Habilita auditoria de logon/logoff |
| RestringePainel | Usuarios | Restringe acesso ao Painel de Controle |
| PermiteRDP | Servidores | Habilita Remote Desktop |

**O que foi feito:**
- Instalação do Windows 11 Enterprise na VM Hyper-V
- Configuração de rede via DHCP (recebendo IP do DC-01)
- Ingresso da máquina ao domínio `lab.brunocastel.com.br`
- Criação e aplicação de 4 GPOs
- Validação: login com usuário de teste, drive S: mapeado automaticamente, políticas aplicadas

---

### Fase 5 — Infraestrutura Azure Base (Terraform)

Provisionamento da infraestrutura base no Azure via Terraform para preparar o ambiente cloud.

| Recurso | Nome | Detalhe |
|---------|------|---------|
| Resource Group | `rg-hybrid-lab` | brazilsouth |
| Virtual Network | `vnet-hub-lab` | 10.1.0.0/16 |
| Subnet | `snet-default` | 10.1.1.0/24 |
| NSG | `nsg-hub-lab` | deny-all implícito |
| Route Table | `rt-hub-lab` | — |
| Log Analytics | `log-hybrid-lab` | PerGB2018, 30 dias retenção |

**Arquivos Terraform:**

```
terraform/
├── providers.tf       # azurerm provider v4.x + backend remoto (Azure Blob)
├── variables.tf       # variáveis com types, descriptions e validações
├── main.tf            # todos os recursos da infra base
├── outputs.tf         # IDs e nomes dos recursos
└── terraform.tfvars   # valores padrão
```

**O que foi feito:**
- Definição do provider azurerm com versão pinada e backend remoto (state locking via Azure Blob Storage)
- Variáveis com validação (location, environment, retention)
- Provisionamento de VNet, Subnet, NSG, Route Table e Log Analytics (todos free-tier)
- Tags obrigatórias em todos os recursos: `environment`, `project`, `managed_by`
- Associação do NSG e Route Table à subnet

**Pré-requisitos para deploy:**
```bash
# 1. Criar backend remoto (uma vez)
az group create --name rg-terraform-state --location brazilsouth
az storage account create --name stterraformstatebc01 --resource-group rg-terraform-state --location brazilsouth --sku Standard_LRS
az storage container create --name tfstate --account-name stterraformstatebc01

# 2. Deploy
cd terraform
terraform init
terraform plan
terraform apply
```

**Verificação de domínio no Entra ID:** Concluída
- Domínio `brunocastel.com.br` adicionado e verificado no Entra ID
- Registro TXT configurado no DNS da Hostinger

---

## Roadmap

| Fase | Descrição | Status |
|------|-----------|--------|
| 1 | Domain Controller + AD DS + DNS + DHCP | Concluída |
| 2 | OUs, Grupos e Usuários | Concluída |
| 3 | File Server + Permissões NTFS | Concluída |
| 4 | CLIENT-01 + GPOs + Validação | Concluída |
| 5 | Infraestrutura Azure Base (Terraform) | Concluída |
| 6 | VM AADC + Entra Connect v2 (Password Hash Sync) | Pendente |
| 7+ | pfSense, VPN S2S, Conditional Access, ASR/DR | Futuro |

## Tecnologias

- **On-Premises:** Windows Server 2019, Hyper-V, Active Directory, DNS, DHCP, GPO, NTFS
- **Estação:** Windows 11 Enterprise
- **Cloud:** Microsoft Azure, Entra ID (Azure AD)
- **IaC:** Terraform (azurerm provider)
- **Networking:** Internal vSwitch, NAT, VNet, Subnet, NSG, Route Table

## Estrutura do Repositório

```
hybrid-lab-ad-entra/
├── terraform/
│   ├── providers.tf
│   ├── variables.tf
│   ├── main.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── docs/
│   └── screenshots/
├── project-guide.md
└── README.md
```

## Autor

**Bruno Castel** — [GitHub](https://github.com/brunokdalcastel)

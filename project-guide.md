# Hybrid Lab AD + Entra ID — Fase 5: Infraestrutura Azure Base

## Objetivo

Provisionar a infraestrutura base no Azure via Terraform para preparar o ambiente cloud do laboratório híbrido. Todos os recursos utilizam free-tier ou camadas gratuitas.

## Arquitetura

```
On-Prem (Hyper-V)              Azure (brazilsouth)
┌──────────────┐               ┌──────────────────────────┐
│  DC-01       │               │  rg-hybrid-lab           │
│  10.0.0.10   │               │  ┌────────────────────┐  │
│  AD DS/DNS   │  ──(futuro)── │  │ vnet-hub-lab       │  │
│  DHCP/Files  │   VPN S2S     │  │ 10.1.0.0/16        │  │
├──────────────┤               │  │  ┌──────────────┐  │  │
│  CLIENT-01   │               │  │  │ snet-default │  │  │
│  DHCP        │               │  │  │ 10.1.1.0/24  │  │  │
│  Win 11 Ent  │               │  │  └──────────────┘  │  │
└──────────────┘               │  └────────────────────┘  │
                               │  nsg-hub-lab             │
                               │  rt-hub-lab              │
                               │  log-hybrid-lab          │
                               └──────────────────────────┘
```

## Pré-requisitos

1. Azure CLI instalado e autenticado (`az login`)
2. Terraform >= 1.5.0 instalado
3. Subscription ativa (free trial ou Pay-As-You-Go)

## Passo 1 — Criar backend remoto (manual, uma vez)

```bash
az group create --name rg-terraform-state --location brazilsouth

az storage account create \
  --name stterraformstatelab \
  --resource-group rg-terraform-state \
  --location brazilsouth \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name stterraformstatelab
```

## Passo 2 — Configurar variáveis

Edite `terraform/terraform.tfvars` se necessário. O `subscription_id` será solicitado no `terraform plan` (ou pode ser passado via variável de ambiente):

```bash
export ARM_SUBSCRIPTION_ID="sua-subscription-id-aqui"
```

Ou crie um arquivo `terraform/secret.tfvars` (já no .gitignore):

```hcl
subscription_id = "sua-subscription-id-aqui"
```

## Passo 3 — Deploy

```bash
cd terraform

terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Passo 4 — Verificar domínio no Entra ID (manual)

1. Acessar [Entra ID → Custom domain names](https://entra.microsoft.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/Domains)
2. Clicar **Add custom domain** → digitar `brunocastel.com.br`
3. Copiar o valor do registro TXT (`MS=msXXXXXXXX`)
4. No painel da **Hostinger** → DNS → criar registro TXT na raiz com esse valor
5. Aguardar propagação DNS (pode levar até 72h, geralmente minutos)
6. Voltar no Entra ID e clicar **Verify**

## Recursos provisionados

| Recurso | Nome | Detalhes |
|---------|------|----------|
| Resource Group | `rg-hybrid-lab` | brazilsouth |
| Virtual Network | `vnet-hub-lab` | 10.1.0.0/16 |
| Subnet | `snet-default` | 10.1.1.0/24 |
| NSG | `nsg-hub-lab` | deny-all implícito |
| Route Table | `rt-hub-lab` | — |
| Log Analytics | `log-hybrid-lab` | PerGB2018, 30 dias retenção |

## Custos

Todos os recursos desta fase são **gratuitos** ou dentro do free-tier:
- VNet, Subnet, NSG, Route Table: sem custo
- Log Analytics: 5 GB/mês gratuitos (tier PerGB2018)

## Próximos passos (Fase 6)

- Criar VM para Entra Connect (AADC) na subnet `snet-default`
- Instalar e configurar Entra Connect v2 (Password Hash Sync)
- Configurar VPN S2S ou alternativa para conectividade on-prem ↔ Azure

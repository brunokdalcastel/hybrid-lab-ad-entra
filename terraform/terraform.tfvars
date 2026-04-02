# ATENCAO: nunca adicione subscription_id ou qualquer secret neste arquivo.
# Use: export ARM_SUBSCRIPTION_ID="..." ou crie terraform/secret.tfvars (ignorado pelo git)

location                     = "brazilsouth"
environment                  = "lab"
project                      = "hybrid-lab"
vnet_address_space           = ["10.1.0.0/16"]
subnet_address_prefixes      = ["10.1.1.0/24"]
log_analytics_retention_days = 30

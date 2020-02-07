# Testing infrastructure-as-code

This Terraform template deploys the infrastructure prerequisites that are required to execute the load test.

You can deploy it using `terraform apply`. The template will output all the configuration values that you can directly copy into `00_configure.sh`, such as storage account key or VNET name.

Before you deploy, make sure to amend the variables for the custom prefix and the deployment location Azure region (or supply the values when applying the template using `-var 'foo=bar'`).
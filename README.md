> Work in progress.

## Requirements

* Bash (or WSL on Windows)
* Azure CLI - configured for current subscription
* Azure resource group with:
	* Azure Container Registry with JMeter images
	* Service principal configured to access Container Registry
	* Storage Account with File storage (Azure Files)
	* Virtual Network

## How to use

1. Prepare Azure Infrastructure (*ARM/Terraform template coming soon*) and get keys to Azure Storage and ACR Service Principal.
1. Prepare Docker images (based on Dockerfiles in the `docker/` folder), publish to Azure Container Registry.
1. Prepare test in JMeter as JMX file.
1. Fill the constants in `00_configure.sh` (description below).
1. Run `01_deploy.sh` and wait - if it fails, investigate and correct manually (currently no failsafes in place).
1. Go to `test.sh` and set up parameters of the test. (Why here? In this way you can quickly change test parameters and re-run it without changing the infrastructure.)
1. Run `02_run.sh` and wait.
1. Once the test completes results will be collected and stored in file share.
1. Infrastructure is reusable - just change test parameters and run again with `02_run.sh`.

Recommended number of USERS is **400** due to thread limitations. If more users are needed, add more agents.

Use command line variables in the JMX test to parametrize load - such as `${__P(users)}`. Example JMX file attached in `definitions/`.

**Use `00_stop.sh` to gracefully terminate running test. Do not Ctrl+C on the master process - it might leave agents in unhealthy state.**

Use `04_download.sh` to download results. Don't forget to update `RESULTS_FILE`. This is just a shorthand for downloading manually from Storage, nothing too fancy.

Use `03_destroy.sh` to remove all agents and master.

## Configuration

| Property             | Meaning                                                      |
|-|-|
|RESOURCE_GROUP|RG name, where the testing infrastructure will live|
|VNET|Virtual Network name, all agents and master will be placed into it|
|SUBNET|Subnet name (can be "default")|
|AGENT_BASE_NAME|Prefix for agent container instances' names|
|MASTER_NAME|Name of container instance of master|
|REGISTRY_USERNAME|App ID of service principal with access to Container Registry|
|REGISTRY_PASSWORD|App secret of service principal with access to Container Registry|
|AGENT_IMAGE|Full image name of agent image (xxxx.azurecr.io/xxxx)|
|MASTER_IMAGE|Full image name of master image (xxxx.azurecr.io/xxxx)|
|STORAGE_ACCOUNT_NAME|Storage account with test definitions and where results will be stored|
|STORAGE_ACCOUNT_KEY|Storage account key|
|STORAGE_SHARE_NAME|File share name (needs to exist)|
|STORAGE_MOUNT_PATH|Linux filesystem path where the share will be mounted|
|AGENT_COUNT|How many agents will be created|
|TARGET_SYSTEM|IP (DNS) of system under load|
|TEST_FILE|Path to the JMX file which should be run. File will be uploaded to file share before running|

## Potential issues

**Watch out for line endings!** When editing on Windows Git can change LF to CRLF - such Bash scripts will **not** work. This repo is configured locally to have automatic CRLF off, make sure that your editor (VS Code) is able to work with LF automatically.

If you get this message when creating master: *The container group 'xxxx' is still transitioning, please retry later.* don't worry about it, just wait for the master to finish provisioning/updating. It usually means that it was configured properly, but is not ready yet.
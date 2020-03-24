# Testing infrastructure-as-code

This Terraform template deploys the infrastructure prerequisites that are required to execute the load test using Azure Virtual Machine Scale Sets.

## Set up

Deployment is orchestrated by the `cross.tf` file. Before running, **you have to supply values** for `prefix` and `main_location`.

* `prefix` will be used as Resource Group name and also a prefix for all resources created. Make sure it's unique and doesn't contain any special characters.
* `main_location` is datacenter where the master node and first group of agents will be. Make sure it's present in `common/common.tf`.

> Take a look in `common/common.tf` to see available locations. If your desired location is missing, add it the list with its corresponding short name (e.g. northeurope -> neu).

## Performance

Virtual machine sizes are specified as `master_vm_size` in the main module and `agent_vm_size` in the agents module. You can experiment with different sizes to find the optmial for your workload and desired performance.

`agent_count` specifies how many agents will be ready to run the test. They are all the same machines in a Virtual Machine Scale Set.

## Running the test

Main deployment script will output the necessary details to finalize master setup and be ready to run the test.

### Get agents' IP adresses

Get agent IP addresses via Azure CLI (use the name of your VM Scale Set for `--vmss-name`):

```bash
az vmss nic list -g <resource group> --vmss-name <prefix>-<short location>-agents --query "[].ipConfigurations[].privateIpAddress"
```

### Connect to master and mount storage

SSH into the master using `master_connection` output credentials:

```bash
ssh adminuser@[your host]
> [your password]
```

Mount Azure Files storage:

```bash
sudo mkdir /mnt/load-tests
sudo mount -t cifs //<your storage account>.file.core.windows.net/test-data /mnt/load-tests -o vers=3.0,username=<your storage account>,password=<your access key>,serverino
```

Upload your jmeter definition file to Azure Files (*.jmx).

### Run the test

JMeter is installed in `$JMETER_HOME` (which is currently `/jmeter/apache-jmeter-5.2.1/`), so just cd to it and start jmeter.

If you want to use parameters in your script (recommended), you can pass values to agents with the `-G` switch (`-Ghost=www.bing.com` - given that the host parameter exists in JMeter configuration). See `../definitions/capacity-test.jmx` for example.

Don't forget the `server.rmi.ssl.disable` parameter.

```bash
cd $JMETER_HOME/bin

sudo ./jmeter -n -f -t /mnt/load-tests/<test-definition>.jmx -l /mnt/load-tests/results/<results file>.csv -R$agent_ips -Ghost=$TARGET_SYSTEM -Gpath=$TARGET_PATH -Gusers=$USERS -Gduration=$DURATION -Gramp_up=$RAMP_UP -Gjmeter.properties.mode=StrippedBatch -Gjmeter.properties.httpclient4.time_to_live=10000 -Gjmeter.properties.httpclient4.validate_after_inactivity=36600 -Djmeter.properties.server.rmi.ssl.disable=true
```
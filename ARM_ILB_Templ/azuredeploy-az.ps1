# Variables that need to be set to start working with ARM.

# The subscriptionId
$subscriptionId = <subscribtion id>


# Root path to script, template and parameters.  All have to be in the same folder.
$rootPathToFiles = Split-Path -Parent $PSCommandPath

# Name of the resource group you are targeting the deployment into
$resourceGroupName = <resource group name>

# Name of the deployment; User friendly name to reference the deployment.
$deploymentName = 'AZ-TESTILB'

# Authenticate Against you Azure Tenant
Login-AzAccount

# List subscriptions that are available to you
Get-AzSubscription

# Select the subscription you want to work on
Set-AzContext -SubscriptionId $subscriptionId

# Run the below to test the ARM template
Test-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile "$rootPathToFiles/azuredeploy.json" -TemplateParameterFile "$rootPathToFiles/azuredeploy.parameters.json" #DEVQA

# Deploy the ARM template using the parameter file
$res = New-AzResourceGroupDeployment -verbose -Name $deploymentName -ResourceGroupName $resourceGroupName -TemplateFile "$rootPathToFiles/azuredeploy.json" -TemplateParameterFile "$rootPathToFiles/azuredeploy.parameters.json" #DEVQA

if($res.ProvisioningState -eq "Succeeded"){

    $VMNames = "AZ-TESTVM01","AZ-TESTVM02"

    $LBName = $res.Outputs.lbName.Value

    $slb = Get-AzLoadBalancer | ?{$_.Name -eq $LBName}

    $BkEnd = $slb | Get-AzLoadBalancerBackendAddressPoolConfig

    foreach ($vmName in $VMNames) {
        $vm = get-AzVm | ?{$_.Name -eq $vmName}
        $NetIntName = $vm.NetworkProfile.NetworkInterfaces[0].Id | Split-Path -Leaf
        $NetInt = Get-AzNetworkInterface -Name $NetIntName -ResourceGroupName $vm.ResourceGroupName
        $NetInt.IpConfigurations[0].LoadBalancerBackendAddressPools=$BkEnd
        Set-AzNetworkInterface -NetworkInterface $NetInt
    }
}

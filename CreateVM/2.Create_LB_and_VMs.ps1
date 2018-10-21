$ResourceGroupName = 'Demonstration1'


$publicIPlb = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName `
                                          -Location "japan east" `
                                          -AllocationMethod "Static" `
                                          -Name "Demonstration1-lbpip3"

$frontendIP = New-AzureRmLoadBalancerFrontendIpConfig -Name "myFrontEndPool" `
                                                      -PublicIpAddress $publicIPlb

$backendPool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name "myBackEndPool"

$lb = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName `
                              -Name "Demonstration-LoadBalancer" `
                              -Location "japan east" `
                              -FrontendIpConfiguration $frontendIP `
                              -BackendAddressPool $backendPool

#Create a health probe
Add-AzureRmLoadBalancerProbeConfig -Name "myHealthProbe" `
                                  -LoadBalancer $lb `
                                  -Protocol tcp `
                                  -Port 80 `
                                  -IntervalInSeconds 15 `
                                  -ProbeCount 2

#o apply the health probe, update the load balancer
Set-AzureRmLoadBalancer -LoadBalancer $lb

#Create Load Balancer Rule
$probe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $lb -Name "myHealthProbe"
Add-AzureRmLoadBalancerRuleConfig -Name "myLoadBalancerRule" `
                                  -LoadBalancer $lb `
                                  -FrontendIpConfiguration $lb.FrontendIpConfigurations[0] `
                                  -BackendAddressPool $lb.BackendAddressPools[0] `
                                  -Protocol Tcp `
                                  -FrontendPort 80 `
                                  -BackendPort 80 `
                                  -Probe $probe

Set-AzureRmLoadBalancer -LoadBalancer $lb

Get-AzureRmPublicIPAddress -ResourceGroupName $ResourceGroupName `
                           -Name "Demonstration1-lbpip3" | select IpAddress

##################################################################################################################
############################Create Virtual Machine################################################################
##################################################################################################################

# Variables for common values
$ResourceGroupName = "Demonstration1"
$location = "japan east"
$vmName01 = "INCHNVMW201601"
$vmName02 = "INCHNVMW201602"
$SubnetName1 = $ResourceGroupName + "subnet01"
$SubnetName2 = $ResourceGroupName + "subnet02"
$VnetName = $ResourceGroupName + "vnet"
$PipName1 = $ResourceGroupName + "pip1"
$PipName2 = $ResourceGroupName + "pip2"
$NsgName = $ResourceGroupName + "nsg"
$InterfaceName1 = $ResourceGroupName + "int1"
$InterfaceName2 = $ResourceGroupName + "int2"

# Create user object
$securePassword = ConvertTo-SecureString 'Password@12345' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("Kumarsu8", $securePassword)

# Create a subnet configuration
Write-Host "Creating Subnets..............."
$subnetConfig1 = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName1 -AddressPrefix 192.168.1.0/24

# Create a subnet configuration
$subnetConfig2 = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName2 -AddressPrefix 192.168.2.0/24
Write-Host "2 Subnets created..............."

Write-Host "Creating virtual Network........"
# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName `
                                  -Location $location `
                                  -Name $VnetName `
                                  -AddressPrefix 192.168.0.0/16 `
                                  -Subnet $subnetConfig1 , $subnetConfig2 
Write-Host "Virtual Network created..............."

Write-Host "Creating Public IDs..................."
# Create a public IP address and specify a DNS name
$pip1 = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName `
                                   -Location $location `
                                   -Name $PipName1 `
                                   -AllocationMethod Static `
                                   -IdleTimeoutInMinutes 4

# Create a public IP address and specify a DNS name
$pip2 = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName `
                                   -Location $location `
                                   -Name $PipName2 `
                                   -AllocationMethod Static `
                                   -IdleTimeoutInMinutes 4
Write-Host "Public IDs Created..................."

Write-Host "Opening port 80..................."
# Create an inbound network security group rule for port 80
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name Port_80 -Protocol Tcp `
                                                   -Direction Inbound `
                                                   -Priority 101 `
                                                   -SourceAddressPrefix * `
                                                   -SourcePortRange * `
                                                   -DestinationAddressPrefix * `
                                                   -DestinationPortRange 80 `
                                                   -Access Allow
Write-Host "Port 80 open -Success..................."
Write-Host "Opening port 80..................."
# Create an inbound network security group rule for port 3389
$nsgRuleRDP1 = New-AzureRmNetworkSecurityRuleConfig -Name Port_3389 -Protocol Tcp `
                                                   -Direction Inbound `
                                                   -Priority 100 `
                                                   -SourceAddressPrefix * `
                                                   -SourcePortRange * `
                                                   -DestinationAddressPrefix * `
                                                   -DestinationPortRange 3389 `
                                                   -Access Allow
Write-Host "Port 80 open -Success..................."

Write-Host "Create Network Security Group..................."
# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName `
                                       -Location $location `
                                       -Name $NsgName `
                                       -SecurityRules $nsgRuleRDP , $nsgRuleRDP1
Write-Host "Network Security Group Created-Success..........."

Write-Host "Create 2 NICs.........."
# Create a virtual network card and associate with public IP address and NSG
$nic1 = New-AzureRmNetworkInterface -Name $InterfaceName1 `
                                    -ResourceGroupName $ResourceGroupName `
                                    -Location $location `
                                    -SubnetId $vnet.Subnets[0].Id `
                                    -PublicIpAddressId $pip1.Id `
                                    -NetworkSecurityGroupId $nsg.Id 
                                    
$nic1.IpConfigurations[0].LoadBalancerBackendAddressPools=$lb.BackendAddressPools[0]
Set-AzureRmNetworkInterface -NetworkInterface $nic1

# Create a virtual network card and associate with public IP address and NSG
$nic2 = New-AzureRmNetworkInterface -Name $InterfaceName2 `
                                    -ResourceGroupName $ResourceGroupName `
                                    -Location $location `
                                    -SubnetId $vnet.Subnets[0].Id `
                                    -PublicIpAddressId $pip2.Id `
                                    -NetworkSecurityGroupId $nsg.Id 

$nic2.IpConfigurations[0].LoadBalancerBackendAddressPools=$lb.BackendAddressPools[0]
Set-AzureRmNetworkInterface -NetworkInterface $nic2


Write-Host "2 NICs Created.........."
Write-Host "Nics added to LoadBalancerBackendAddressPools......"


Write-Host "Creating AvaiablitySet...................."
$availabilitySet = New-AzureRmAvailabilitySet `
                    -ResourceGroupName Demonstration1 `
                    -Name "myAvailabilitySet" `
                    -Location japaneast `
                    -Sku aligned `
                    -PlatformFaultDomainCount 2 `
                    -PlatformUpdateDomainCount 2
Write-Host "AvaiablitySet Created-Success............."


# Create a virtual machine configuration
Write-Host "Creating VM configuration 1..................."
$vmConfig1 = New-AzureRmVMConfig -VMName $vmName01 `
                                 -VMSize Standard_D2_v2 `
                                 -AvailabilitySetId $availabilitySet.Id | `
Set-AzureRmVMOperatingSystem -Windows `
                             -ComputerName $vmName01 `
                             -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer `
                         -Offer WindowsServer `
                         -Skus 2016-Datacenter `
                         -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic1.Id

# Create a virtual machine configuration
Write-Host "Creating VM configuration 2..................."
$vmConfig2 = New-AzureRmVMConfig -VMName $vmName02 `
                                 -VMSize Standard_D2_v2 `
                                 -AvailabilitySetId $availabilitySet.Id | `
Set-AzureRmVMOperatingSystem -Windows `
                             -ComputerName $vmName02 `
                             -Credential $cred | `
Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer `
                         -Offer WindowsServer `
                         -Skus 2016-Datacenter `
                         -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic2.Id
Write-Host "VM configuration 1 and 2 created successfully........"
# Create a virtual machine
Write-Host "Creating Virtual Machine 1..................."
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig1
Write-Host "Virtual Machine 1 created successfully......."

# Create a virtual machine
Write-Host "Creating Virtual Machine 2..................."
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $vmConfig2
Write-Host "Virtual Machine 2 created successfully......."

#Install IIS on Target Machines
Write-Host "Installing IIS on VM 1......."
Set-AzureRmVMExtension `
     -ResourceGroupName $ResourceGroupName `
     -ExtensionName "IIS" `
     -VMName $vmName01 `
     -Publisher Microsoft.Compute `
     -ExtensionType CustomScriptExtension `
     -TypeHandlerVersion 1.8 `
     -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
     -Location "japaneast"
Write-Host "Installing IIS on VM 1-SUCCESS"

Write-Host "Installing IIS on VM 2......."
Set-AzureRmVMExtension `
     -ResourceGroupName $ResourceGroupName `
     -ExtensionName "IIS" `
     -VMName $vmName02 `
     -Publisher Microsoft.Compute `
     -ExtensionType CustomScriptExtension `
     -TypeHandlerVersion 1.8 `
     -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
     -Location "japaneast"
Write-Host "Installing IIS on VM 2-SUCCESS"

Get-AzureRmPublicIPAddress `
  -ResourceGroupName $ResourceGroupName `
  -Name "Demonstration1-lbpip3" | select IpAddress



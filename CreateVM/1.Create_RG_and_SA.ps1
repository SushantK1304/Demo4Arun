#Variables
$ResourceGroupName = 'Demonstration1'
$storageaccountname = 'storageaccount4demo'

#create a new resource group
if(Get-AzureRmResource | where {$_.ResourceGroupName -eq $ResourceGroupName})
{
Get-AzureRmResourceGroup -Name $ResourceGroupName | Remove-AzureRmResourceGroup -Verbose -Force
}

#to create a new resource group and automation account
New-AzureRmResourceGroup -Name $ResourceGroupName `
                         -Location 'japaneast'


#create a new storage acccount
if(Get-AzureRmStorageAccount | where {$_.StorageAccountName -eq $storageaccountname})
{
Get-AzureRmStorageAccount -Name $storageaccountname | Remove-AzureRmStorageAccount -Verbose -Force
}

New-AzureRmStorageAccount -ResourceGroupName $ResourceGroupName `
                          -AccountName $storageaccountname `
                          -Location "japaneast" `
                          -SkuName "Standard_LRS" `
                          -Kind Storage

$accountKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $storageaccountname).Value[0]
$context = New-AzureStorageContext -StorageAccountName $storageaccountname `
                                   -StorageAccountKey $accountKey 

New-AzureStorageContainer -Name "templates" `
                          -Context $context `
                          -Permission Container
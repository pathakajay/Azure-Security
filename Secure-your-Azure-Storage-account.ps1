#connect to Azure
Connect-AzureRmAccount
$resourceGroupName="ajay20190803"
$location="centralus"

New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

$storageAccount="saajay20190803"
New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -Location $location -SkuName Standard_LRS

#To use customer-managed keys with SSE, you must assign a storage account identity to the storage account. 
Set-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccount -AssignIdentity

#enable Soft Delete and Do Not Purge by executing the following PowerShell commands
$vaultName = "ajayvault20180803"
$keyvault=New-AzureRmKeyVault -Name $vaultName -ResourceGroupName $resourceGroupName -Location $location 
($resource = Get-AzureRmResource -ResourceId (Get-AzureRmKeyVault -VaultName $vaultName).ResourceId).Properties `
 | Add-Member -MemberType NoteProperty -Name enableSoftDelete -Value 'True'

Set-AzureRmResource -resourceid $resource.ResourceId -Properties $resource.Properties

($resource = Get-AzureRmResource -ResourceId (Get-AzureRmKeyVault -VaultName $vaultName).ResourceId).Properties `
| Add-Member -MemberType NoteProperty -Name enablePurgeProtection -Value 'True'

Set-AzureRmResource -resourceid $resource.ResourceId -Properties $resource.Properties

#custermanagedkey01

#associate the above key with an existing storage account using the following PowerShell commands
$storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccount


$kv = Get-AzureRmKeyVault -VaultName $vaultName
$keyname= "custermanagedkey01"
Add-AzureKeyVaultKey -VaultName $vaultName -Name $keyname -Destination Software 
$key = Get-AzureKeyVaultKey -VaultName $vaultName -Name $keyname
$key.Name
$key.Version

Set-AzureRmKeyVaultAccessPolicy -VaultName $kv.VaultName -ObjectId $storageAccount.Identity.PrincipalId `
-PermissionsToKeys wrapkey,unwrapkey,get

Set-AzureRmStorageAccount -ResourceGroupName $storageAccount.ResourceGroupName -AccountName $storageAccount.StorageAccountName `
-KeyvaultEncryption -KeyName $key.Name -KeyVersion $key.Version -KeyVaultUri $kv.VaultUri

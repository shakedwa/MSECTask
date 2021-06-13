function installNeededModuls {
  write-host "Installing AzureRM "
  Install-Module AzureRM -force
}

function connectToAzAccount {
  write-host "Connecting"
  Connect-AzAccount
  write-host "Connection Succeed."
 }

function createResourceGroup {
  param(
    $rgname,
    $rgLocation
  )
  write-host "creating Resource Group"
  New-AzResourceGroup `
      -Name $rgname `
      -Location $rgLocation
}

function deployTemplate {
  param(
    $rgname,
    $templateFilePath,
    $templateParametesFile
  ) 
  New-AzResourceGroupDeployment `
      -ResourceGroupName $rgname `
      -TemplateFile $templateFilePath `
      -TemplateParameterFile $templateParametesFile
}

function deployStorageAccount {
  param(
    $rgname,
    $templateStorageFilePath,
    $templateStorageParamsFilePath
  )
  write-host "deploying storage account template"
  deployTemplate -rgname $rgname -templateFilePath $templateStorageFilePath -templateParametesFile $templateStorageParamsFilePath 
}

function deployServer {
  param(
    $rgname,
    $templateServerFilePath,
    $templateServerParamsFilePath
  )
  write-host "deploying server template" 
  deployTemplate -rgname $rgname -templateFilePath $templateServerFilePath -templateParametesFile $templateServerParamsFilePath 
}

#Declare variables
$rgname = "ShakedWaMSECTaskResourceGroup"
$rgLocation = "uaenorth"
$templateStorageFilePath = "$pwd\storageAccount\template.json"
$templateStorageParamsFilePath = "$pwd\storageAccount\parameters.json"
$templateServerFilePath = "$pwd\VM\template.json"
$templateServerParamsFilePath = "$pwd\VM\parameters.json"

#installNeededModuls
connectToAzAccount

#create Resource Group
createResourceGroup -rgname $rgname -rgLocation $rgLocation

#deploy storage account template
deployStorageAccount -rgname $rgname -templateStorageFilePath $templateStorageFilePath -templateStorageParamsFilePath $templateStorageParamsFilePath

#deploy server template
deployServer -rgname $rgname -templateServerFilePath $templateServerFilePath -templateServerParamsFilePath $templateServerParamsFilePath
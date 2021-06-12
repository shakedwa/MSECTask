function createFiles{
    1..5 | foreach { 
      $file = "$pwd\Files\$_.txt"
      if (!([System.IO.File]::Exists($file))){
          new-item -path $file 
      }else {
          $fileName = (Split-Path -Path $file -Leaf)
          Write-Host (-join($fileName, " already exists"))
      }
  }
}

function install {
  write-host "Installing AzureRM "
  Install-Module AzureRM -force
}

function connect {
  
 write-host "Connecting"
  Connect-AzAccount
  write-host "Connection Succeed."
}

 function getStorageAccount {

      $storageAccount = Get-AzStorageAccount `
          -ResourceGroupName $rgname `
          -Name $storageaccountname `
          -ErrorAction SilentlyContinue
      $context = $storageAccount.Context
      return $context

   param (
      $rgname,
      $storageaccountname
   )
 }

 function createContainer {

    $container = Get-AzStorageContainer `
      -Name $containerName `
      -Context $context `
      -ErrorAction SilentlyContinue

    #create if needed
    if(!$container)  
    {  
      $container = New-AzStorageContainer `
      -Name $containerName `
      -Context $context `
      -Permission blob    
    } 
    return $container

  param (
    $containerName,
    $context
  )
}

function uploadFiles {

if($container)
{
    $files = Get-ChildItem -Path $fileslocation
    foreach ($file in $files)
    {
          $ext = (Split-Path -Path $file -Leaf).Split(".")[1];
          Set-AzStorageBlobContent `
          -File (-join($fileslocation , $file)) `
          -Container $containerName `
          -Blob $([guid]::NewGuid().ToString() + "." + $ext)  `
          -Context $context
    }
    $blobs = Get-AzStorageBlob `
      -Container $containerName `
      -Context $context
    $totalfiles = $blobs.Count                                                                
    write-host -ForegroundColor Green $totalfiles `
                "files are uploaded successfully"
    return $blobs
}
  param (
    $container,
    $fileslocation,
    $containerName,
    $context
  )
}

function copyBlobs {

  foreach ($blob in $blobs){
    Start-AzStorageBlobCopy -SrcBlob $blob.name `
    -SrcContainer $containerName `
    -Context $context `
    -DestBlob $blob.name `
    -DestContainer $containerName `
    -DestContext $context2   
  }
  $blobs2 = Get-AzStorageBlob `
  -Container $containerName `
  -Context $context2
  $totalfiles2 = $blobs2.Count                                                                
  write-host -ForegroundColor Green $totalfiles2 `
            "files are copyed successfully"
  return $blobs         
  param (
    $blobs,
    $containerName,
    $context,
    $context2
  )
}

createFiles
install
connect
$rgname = 'MSECTaskResourceGroup'
$storageaccountname = '0storagercuz53g4tezru'
$storageaccountname2 = '1storagercuz53g4tezru'
$containerName = 'msectaskcontainer'
$fileslocation = "$pwd\Files\"

#get first storage account
$retContextVal = getStorageAccount -rgname $rgname -storageaccountname $storageaccountname
$context = $retContextVal[0]

#create first container match the first storage account
$retContainerVal = createContainer -containerName $containerName -context $context
$container = $retContainerVal[0]

#get second storage account
$retContextVal = getStorageAccount -rgname $rgname -storageaccountname $storageaccountname2
$context2 = $retContextVal[0]

#create second container match the second storage account
$retContainerVal = createContainer -containerName $containerName -context $context2

#Upload files and get the files count
#uploaded in the blob container.
$retBlobVal = uploadFiles -container $container -fileslocation $fileslocation -containerName $containerName -context $context
$blobs = $retBlobVal[0]

#iteration over all blob in storage accout and copy to second storage accout
copyBlobs -blobs $blobs -containerName $containerName -context $context -context2 $context2
      
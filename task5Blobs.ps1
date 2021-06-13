function createFiles{
    1..100 | foreach { 
      $file = "$pwd\Files\$_.txt"
      if (!([System.IO.File]::Exists($file))){
          new-item -path $file 
      }else {
          $fileName = (Split-Path -Path $file -Leaf)
          Write-Host (-join($fileName, " already exists"))
      }
  }
}

function installNeededModuls {
  write-host "Installing AzureRM "
  Install-Module AzureRM -force -AllowClobber
}

function connectToAzAccount {
 write-host "Connecting"
 Connect-AzAccount
 write-host "Connection Succeed."
}

 function getStorageAccount {
    param (
        $rgname,
        $storageaccountname
    )
    $storageAccount = Get-AzStorageAccount `
        -ResourceGroupName $rgname `
        -Name $storageaccountname `
        -ErrorAction SilentlyContinue
    $context = $storageAccount.Context
    return $context
 }

 function createContainer {
    param (
      $containerName,
      $context
    )
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
}

function uploadFiles {
  param (
    $container,
    $fileslocation,
    $containerName,
    $context
  )
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
}

function copyBlobs {
  param (
    $blobs,
    $containerName,
    $context,
    $context2
  )
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
            "files are copied successfully"
  return $blobs         
}


$rgname = 'ShakedWaMSECTaskResourceGroup'
$storageaccountname = '0storage33twwzdzbaoms'
$storageaccountname2 = '1storage33twwzdzbaoms'
$containerName = 'msectaskcontainer'
$fileslocation = "$pwd\Files\"

createFiles
#installNeededModuls
connectToAzAccount

#get first storage account
$retContextVal = getStorageAccount -rgname $rgname -storageaccountname $storageaccountname

#create first container match the first storage account
$retContainerVal = createContainer -containerName $containerName -context $retContextVal

#get second storage account
$retContextVal2 = getStorageAccount -rgname $rgname -storageaccountname $storageaccountname2

#create second container match the second storage account
$retContainerVal = createContainer -containerName $containerName -context $retContextVal2

#Upload files and get the files count
#uploaded in the blob container.
$retBlobVal = uploadFiles -container $retContainerVal -fileslocation $fileslocation -containerName $containerName -context $retContextVal

#iteration over all blob in storage accout and copy to second storage accout
copyBlobs -blobs $retBlobVal -containerName $containerName -context $retContextVal -context2 $retContextVal2
      

$currentyProdFiles = @(
    'C:\scenario\app\prodTargetFolder\HomeController.cs',
    'C:\scenario\app\prodTargetFolder\IDocumentDBRepository.cs'
    #'C:\scenario\app\prodTargetFolder\config\Tailspin.SpaceGame.Web.csproj'
)

$newFilesToDeploy = @(
    'C:\scenario\newFilesFolder\HomeController.cs',
    'C:\scenario\newFilesFolder\IDocumentDBRepository.cs'
    #'C:\scenario\newFilesFolder\Tailspin.SpaceGame.Web.csproj'
)

$folderToOldFiles = 'C:\scenario\_old'
$productionEnv = 'C:\scenario\app\prodTargetFolder'

function Test-PathsExist {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$paths
    )

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                             START - TEST PATHS                                          |"
    Write-Host "+-+---------------------------------------------------------------------------------------+"

    $pathNotFound = $false
    foreach ($path in $paths) {

        if (Test-Path -Path $path -PathType Leaf) {
            Write-Host -ForegroundColor Green "|#| File in path $path found."
        }
        else {
            Write-Error "|#| File in path $path not found."
            $pathNotFound = $true
        }
    }
    if ($pathNotFound) {
        Write-Host "+-+---------------------------------------------------------------------------------------+"
        Write-Host "|                            END - TEST PATHS                                             |"
        Write-Host "+-+---------------------------------------------------------------------------------------+"
        exit 1
    }

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                            END - TEST PATHS                                             |"
    Write-Host "+-+---------------------------------------------------------------------------------------+`n"
}

function Move-OldFiles {
    param(
        [string[]]$oldFilesToMove
    )

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                            INIT - MOVE/RENAME OLD FILES                                 |"
    Write-Host "+-+---------------------------------------------------------------------------------------+"

    foreach ($file in $oldFilesToMove) {

        Write-Host "|#| Moving file $file"
    
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $fileExtension = [System.IO.Path]::GetExtension($file)
        $newFileName = "${fileName}_old$fileExtension"
        $oldFilesDestination = Join-Path -Path $folderToOldFiles -ChildPath $newFileName
    
        if (Test-Path -Path $oldFilesDestination -PathType Leaf) {
            Write-Host -ForegroundColor red "|#| The file on $oldFilesDestination already exists, deleting it."
            Remove-Item -Path $oldFilesDestination
        }
    
        $fileInfo = Get-Item -Path $file
        $lastWriteTime = $fileInfo.LastWriteTime
        
        Move-Item -Path $file -Destination $oldFilesDestination
        
        Write-Host -ForegroundColor Green "|#| Old file $file moved successfully"
        Write-Host "|#| Last Update in $lastWriteTime"
    
        Write-Host "+-+---------------------------------------------------------------------------------------+"
    }

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                            END - MOVE/RENAME OLD FILES                                  |"
    Write-Host "+-+---------------------------------------------------------------------------------------+`n"
}

function Add-NewFilesToProductionEnv {
    param(
        [string[]]$newFiles
    )

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                            INIT - ADD NEW FILES                                         |"
    Write-Host "+-+---------------------------------------------------------------------------------------+"

    foreach ($file in $newFiles) {
        Write-Host "|#| Adding new file $file"

        Copy-Item -Path $file -Destination $productionEnv

        $fileInfo = Get-Item -Path $file
        $lastWriteTime = $fileInfo.LastWriteTime
        
        Write-Host "|#| Last file update in $lastWriteTime"
        Write-Host -ForegroundColor Green "|#| File $file added  `n|#| Folder: $productionEnv"
        Write-Host "|+|"
    }

    Write-Host "+-+---------------------------------------------------------------------------------------+"
    Write-Host "|                            END - ADD NEW FILES                                          |"
    Write-Host "+-+---------------------------------------------------------------------------------------+`n"

}

Test-PathsExist -paths ($currentyProdFiles + $newFilesToDeploy)
Move-OldFiles -oldFilesToMove $currentyProdFiles
Add-NewFilesToProductionEnv -newFiles $newFilesToDeploy

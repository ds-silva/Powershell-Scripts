
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

    Write-Host "START - TEST PATHS"
    Write-Host ""

    $pathNotFound = $false
    foreach ($path in $paths) {

        if (Test-Path -Path $path -PathType Leaf) {
            Write-Host "File in path $path found."
        }
        else {
            Write-Error "File in path $path not found."
            $pathNotFound = $true
        }
    }
    if ($pathNotFound) {
        Write-Host ""
        Write-Host "END - TEST PATHS"
        exit 1
    }

    Write-Host ""
    Write-Host "END - TEST PATHS"
}

function Move-OldFiles {
    param(
        [string[]]$oldFilesToMove
    )

    Write-Host ""
    Write-Host "INIT - MOVING OLD FILES"
    Write-Host ""

    foreach ($file in $oldFilesToMove) {

        Write-Host "Moving file $file"
    
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $fileExtension = [System.IO.Path]::GetExtension($file)
        $newFileName = "${fileName}_old$fileExtension"
        $oldFilesDestination = Join-Path -Path $folderToOldFiles -ChildPath $newFileName
    
        if (Test-Path -Path $oldFilesDestination -PathType Leaf) {
            Write-Warning "File $oldFilesDestination already exists, deleting it..."
    
            Remove-Item -Path $oldFilesDestination
            Write-Host "File $oldFilesDestination removed successfully `n"
        }
    
        $fileInfo = Get-Item -Path $file
        $lastWriteTime = $fileInfo.LastWriteTime
        Write-Host "Last Update in $lastWriteTime"
    
        Move-Item -Path $file -Destination $oldFilesDestination
        Write-Host "Old file $file moved successfully `n"
    
        Write-Host "------------------------------------------------------------------------------------------------"
    }

    Write-Host ""
    Write-Host "END - MOVING OLD FILES"
    Write-Host ""
}

function Add-NewFilesToProductionEnv {
    param(
        [string[]]$newFiles
    )

    Write-Host "INIT - ADD NEW FILES"
    Write-Host ""

    foreach ($file in $newFiles) {
        Write-Host "Adding new file $file"

        Copy-Item -Path $file -Destination $productionEnv

        $fileInfo = Get-Item -Path $file
        $lastWriteTime = $fileInfo.LastWriteTime
        Write-Host "Last update in $lastWriteTime"

        Write-Host "New file $file added to folder $productionEnv `n"
    }

    Write-Host ""
    Write-Host "END - ADD NEW FILES"

}

Test-PathsExist -paths ($currentyProdFiles + $newFilesToDeploy)
Move-OldFiles -oldFilesToMove $currentyProdFiles
Add-NewFilesToProductionEnv -newFiles $newFilesToDeploy

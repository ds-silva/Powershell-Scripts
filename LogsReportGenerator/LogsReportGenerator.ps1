function Get-FolderSize {
    param (
        [string]$folderPath
    )

    $folder = Get-Item $folderPath

    if ($folder -is [System.IO.DirectoryInfo]) {
        $size = 0
        Get-ChildItem $folder.FullName -Recurse | ForEach-Object {
            $size += $_.Length
        }
        $size
    }
}

function Get-DriveInfo {
    param (
        [string]$driveLetter
    )

    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"

    if ($drive) {
        $driveInfo = [ordered]@{
            TotalSizeGB      = $drive.Size / 1GB
            FreeSpaceGB      = $drive.FreeSpace / 1GB
            UsedSpaceGB      = ($drive.Size - $drive.FreeSpace) / 1GB
            UsedSpacePercent = ($drive.Size - $drive.FreeSpace) / $drive.Size * 100
        }

        $driveInfo
    }
}

function Format-Size {
    param (
        [long]$size
    )

    $gbSize = $size / 1GB
    $mbSize = $size / 1MB
    $kbSize = $size / 1KB

    if ($gbSize -ge 1) {
        "{0:N2} GB" -f $gbSize
    }
    elseif ($mbSize -ge 1) {
        "{0:N2} MB" -f $mbSize
    }
    elseif ($kbSize -ge 1) {
        "{0:N2} KB" -f $kbSize
    }
    else {
        "{0:N2} Bytes" -f $size
    }
}

function Get-CriticidadeColor {
    param (
        [long]$size
    )

    if ($size -gt 900MB) {
        return "red"
    }
    elseif ($size -gt 700MB -and $size -le 900MB) {
        return "orange"
    }
    else {
        return "green"
    }
}

$currentDirectory = $PWD.ProviderPath
$driveInfo = Get-DriveInfo -driveLetter "C:"

$htmlDriveInfo = @"
<h2>Informações do Disco</h2>
<table>
    <tr>
        <th>Total de Disco (GB)</th>
        <th>Espaço Utilizado (GB)</th>
        <th>Espaço Livre (GB)</th>
        <th>Utilizado (%)</th>
    </tr>
    <tr>
        <td>$($driveInfo["TotalSizeGB"].ToString("N2", [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")))</td>
        <td>$($driveInfo["UsedSpaceGB"].ToString("N2", [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")))</td>
        <td>$($driveInfo["FreeSpaceGB"].ToString("N2", [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")))</td>
        <td>$($driveInfo["UsedSpacePercent"].ToString("N2", [System.Globalization.CultureInfo]::GetCultureInfo("pt-BR")))%</td>
    </tr>
</table>
"@

$htmlFolders = @"
<h2>Informações de Pastas</h2>
<div class='scrollable-table'>
    <table id='folderTable'>
        <tr>
            <th>Nome da Pasta</th>
            <th>Tamanho</th>
            <th>Criticidade</th>
        </tr>
"@

foreach ($folder in (Get-ChildItem $currentDirectory -Directory -Recurse | Where-Object { (Get-FolderSize $_.FullName) -gt 0 })) {
    $folderSize = Get-FolderSize -folderPath $folder.FullName
    $formattedSize = $(Format-Size $folderSize)
    $criticidadeColor = $(Get-CriticidadeColor $folderSize)
    
    $htmlFolders += @"
    <tr>
        <td>$($folder.FullName)</td>
        <td>$formattedSize</td>
        <td><div style='width: 20px; height: 20px; border-radius: 5px; background-color: $criticidadeColor;'></div></td>
    </tr>
"@
}

$htmlFolders += @"
    </table>
</div>
"@


$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
<meta charset='UTF-8'/>
<title>Report - Tamanho das Pastas de Log</title>
<style>
body {
    font-family: 'Arial', sans-serif;
    background-color: #f4f4f4;
    color: #333;
    margin: 2;
    padding: 0;
}

h1 {
    color: #333;
    text-align: center;
    margin-top: 20px;
}

table {
    border-collapse: collapse;
    width: 100%;
    box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
    background-color: #fff;
}

th, td {
    border: 1px solid #ddd;
    padding: 15px;
    text-align: left;
}

th {
    background-color: #f2f2f2;
    color: #555;
}

tr:nth-child(even) {
    background-color: #f9f9f9;
}

.search-box {
    margin-bottom: 20px;
}

.criticidade-square {
    width: 20px;
    height: 20px;
}

.scrollable-table {
    max-height: 400px;
    overflow-y: auto;
}
</style>
</head>
<body>
<h1>Report - Tamanho das Pastas de Log</h1>
<div class='search-box'>
<label for='search'>Filtrar por nome:</label>
<input type='text' id='search' onkeyup='filterTable()' placeholder='Digite o nome da pasta'>
</div>

$htmlDriveInfo
$htmlFolders

<script>
function filterTable() {
    var input, filter, table, tr, td, i, txtValue;
    input = document.getElementById('search');
    filter = input.value.toUpperCase();
    table = document.getElementById('folderTable');
    tr = table.getElementsByTagName('tr');
            
    for (i = 1; i < tr.length; i++) {
        td = tr[i].getElementsByTagName('td')[0];
        if (td) {
            txtValue = td.textContent || td.innerText;
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = '';
            } else {
                tr[i].style.display = 'none';
            }
        }       
    }
}
</script>
</body>
</html>
"@

$htmlFilePath = "LogsReportGenerator.html"
$htmlHeader | Out-File -FilePath $htmlFilePath -Encoding UTF8

Write-Host "Relatório salvo em: $htmlFilePath"


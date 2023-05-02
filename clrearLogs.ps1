$logsPathListStr = "C:\log;C:\inetpub\logs"
$logsPathList = $logsPathListStr.split(";");
$retentionsDaysListStr = "15;10"
$retentionsDaysList = $retentionsDaysListStr.split(";");
$loopExecutionTime = $logsPathList.length;

for ($i=0; $i -ne $loopExecutionTime; $i++)
{
  $pathsAndDates = @(
    $data = @(
      [pscustomobject]@{path=$logsPathList[$i];date=$retentionsDaysList[$i]}
    )
  )

  $data | ForEach-Object {
    $path = $_.path;
    $date = $_.date;

    $cmd = "cd -d ""$path"""
    Write-Output "Exec: $cmd"
    Invoke-Expression $cmd
    
    $cmd = "Get-ChildItem -Include *.log -Recurse | Where-Object {(`$_.LastWriteTime -lt (Get-Date).AddDays(-$date) )} | Remove-Item"
    Write-Output "Exec: $cmd"
    Invoke-Expression $cmd
  }
}
$logsPathListStr = "C:\log;C:\inetpub\logs"
$logsPathList = $logsPathListStr.split(";");

$retentionsDaysListStr = "5;10"
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

    $files = Get-ChildItem $path | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$date) }

    if ($files.Count -gt $date)
    {
      $cmd = "cd -d ""$path"""
      Write-Output "Exec: $cmd"
      Invoke-Expression $cmd

      foreach ($file in $files)
      {
        Write-Output $file.Name
      }

      $cmd = "Get-ChildItem -Include *.log,*.txt,*.json -Recurse | Where-Object {(`$_.LastWriteTime -lt (Get-Date).AddDays(-$date))} | Remove-Item"
      Write-Output "Exec: $cmd"
      Invoke-Expression $cmd
    }
    else
    {
      Write-Output "There are no files in $path with more than $date days."
    }
  }
}
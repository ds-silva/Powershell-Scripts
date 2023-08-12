$logsPathListStr = "C:\log;C:\inetpub\logs"
$logsPathList = $logsPathListStr.split(";");

$retentionsDaysListStr = "5;10"
$retentionsDaysList = $retentionsDaysListStr.split(";");

$loopExecutionTime = $logsPathList.length;

for ($i = 0; $i -ne $loopExecutionTime; $i++) {
  $pathsAndDates = @(
    $data = @(
      [pscustomobject]@{path = $logsPathList[$i]; date = $retentionsDaysList[$i] }
    )
  )

  $data | ForEach-Object {
    $path = $_.path;
    $date = $_.date;

    # Adding error handling around Get-ChildItem
    try {
      $files = Get-ChildItem $path | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$date) }
    }
    catch {
      Write-Output "Error occurred while getting files from $path: $_"
      continue  # Move to the next iteration in case of an error
    }

    if ($files.Count -gt $date) {
      $cmd = "cd -d ""$path"""
      Write-Output "Exec: $cmd"
      Invoke-Expression $cmd

      foreach ($file in $files) {
        Write-Output $file.Name
      }

      # Adding error handling around Remove-Item
      try {
        $cmd = "Get-ChildItem -Include *.log,*.txt,*.json -Recurse | Where-Object {(`$_.LastWriteTime -lt (Get-Date).AddDays(-$date))} | Remove-Item"
        Write-Output "Exec: $cmd"
        Invoke-Expression $cmd
      }
      catch {
        Write-Output "Error occurred while removing files: $_"
      }
    }
    else {
      Write-Output "No files found in $path that are more than $date days old."
    }
  }
}

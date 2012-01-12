$watcher = New-Object IO.FileSystemWatcher "." -Property @{
    IncludeSubdirectories = $true
    EnableRaisingEvents = $true
}

"Waiting for changes"

while($true) {
  $changed = $watcher.WaitForChanged("All")

  if ($changed.Name.Contains("specs") -or
      $changed.Name.Contains("lib") -or
      $changed.Name.Contains("src"))
     {
        start-sleep -s 1
        &.\build\run-build-file.bat UpdateExamples

        "Waiting for changes"
     }
}
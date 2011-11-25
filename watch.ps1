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
        start-sleep -s 2
        &.\build\run-build-file.bat CoreCompile

        "Waiting for changes"
     }
}
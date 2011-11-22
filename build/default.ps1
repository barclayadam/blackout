Import-Module '.\teamcity.psm1'

$CurrentDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    
properties {     
    $OutputDirectory = "$CurrentDir\output"

    $SpecRunnerPath = "runner.html"
    $JsTestsFolder = "$CurrentDir\..\specs\"
    $PhantomJsToolPath = "$CurrentDir\tools\phantomjs\phantomjs.exe"
}

function CreateDirectoryIfMissing([string]$Directory) {
    if(!(Test-Path $Directory)) {
        md $Directory > $null
    }
}

<#
 Report build progress to TeamCity whenever a task starts, in addition to setting up
 output directories most tasks require.
#>
TaskSetup {
    TeamCity-ReportBuildStart "Running task $($script:context.Peek().currentTaskName)"
}

<#
 Report build progress to TeamCity whenever a task completes.
#>
TaskTearDown {
    TeamCity-ReportBuildFinish "Running task $($script:context.Peek().currentTaskName)"	
}

<#
 Cleans the output folder and allows the solution to be cleansed, performing the same action
 as the Visual Studio 'Clean' command.
#>
task Clean {    
    if(Test-Path $OutputDirectory) {
        rm -Recurse -Force $OutputDirectory
    }
}

<#
 'Compiles' the project by creating a concatenated version of the library and specs, 
 compiled to JavaScript.
#>
task CoreCompile -depends Clean {        
    CreateDirectoryIfMissing $OutputDirectory

    $OutDebugFile = "output\blackout-latest"
    $OutDebugFileSpec = "output\blackout-latest.spec"
    
    # Source    
    [string]::join([environment]::newline, (gc version-header.coffee)).Replace('$Version', (gc "..\version.txt")) | Out-File "$OutDebugFile.coffeescript" -encoding "ascii"

    type "..\src\module.txt" | foreach {ac "$OutDebugFile.coffeescript" (gc "..\$_")}
    tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -c "$OutDebugFile.coffeescript"

    # Spec
    type "..\specs\module.txt" | foreach {ac "$OutDebugFileSpec.coffeescript" (gc "..\$_")}
    tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -c "$OutDebugFileSpec.coffeescript"
}

<#
 Performs the JavaScript tests using PhantomJs, reporting the results as an NUnit file to be included
 in TeamCity.
#>
task JsTests -depends CoreCompile {                                
    cd $JsTestsFolder    
    &$PhantomJsToolPath "phantomjs_runner.js" "$SpecRunnerPath" "$OutputDirectory\test-result.png"
    $TestsFailed = $lastexitcode -ne 0
    
    if ($TestsFailed) {
        throw "JS Tests have failed"
    }

    cd $CurrentDir
}

task NuGet -depends CoreCompile, JsTests {
    $Version = (gc "..\version.txt")
    $NuspecFile = "Blackout.v$Version.nuspec"
    $NupkgFile = "Blackout.$Version.nupkg"

    [string]::join([environment]::newline, (gc Blackout.nuspec)).Replace('$Version', $Version) | Out-File $NuspecFile -encoding "ascii"

    &.\tools\nuget.exe pack $NuspecFile
    &.\tools\nuget.exe push $NupkgFile -s $NuGetUrl $NuGetKey

    del $NuspecFile
    del $NupkgFile
}

task TeamCityBuild -depends CoreCompile,JsTests,NuGet
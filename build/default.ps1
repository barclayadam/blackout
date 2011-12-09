Import-Module '.\teamcity.psm1'

$CurrentFolder = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    
properties {
    $BuildNumber = if ("$env:BUILD_NUMBER".length -gt 0) { "$env:BUILD_NUMBER" } else { "0" }
    $Version = "0.1." + $BuildNumber
    $OutputFolder = "$CurrentFolder\output"

    $SpecRunnerPath = "runner.html"
    $JsTestsFolder = "$CurrentFolder\..\specs\"
    $PhantomJsToolPath = "$CurrentFolder\tools\phantomjs\phantomjs.exe"
}

function CreateFolderIfMissing([string]$Folder) {
    if(!(Test-Path $Folder)) {
        md $Folder > $null
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
    if(Test-Path $OutputFolder) {
        rm -Recurse -Force $OutputFolder
    }
}

<#
 'Compiles' the project by creating a concatenated version of the library and specs,
 compiled to JavaScript.
#>
task CoreCompile -depends Clean {
    CreateFolderIfMissing "$OutputFolder\src"
    CreateFolderIfMissing "$OutputFolder\specs"

    type "..\src\module.txt" | foreach { tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -o "$OutputFolder\src" -c "..\$_" }

    # Spec
    type "..\specs\module.txt" | foreach { tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -o "$OutputFolder\specs" -c "..\$_" }
}

<#
 Creates a concatenated version of the library and specs, compiled to JavaScript.
#>
task Concatenate -depends Clean {
    CreateFolderIfMissing "$OutputFolder"

    $OutDebugFile = "output\blackout-latest"
    $OutDebugFileSpec = "output\blackout-latest.spec"
    
    # Source    
    [string]::join([environment]::newline, (gc version-header.coffee)).Replace('$Version', $Version) | Out-File "$OutDebugFile.coffeescript" -encoding "ascii"

    type "..\src\module.txt" | foreach {ac "$OutDebugFile.coffeescript" (gc "..\$_")}
    tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -c "$OutDebugFile.coffeescript"

    # Spec
    type "..\specs\module.txt" | foreach {ac "$OutDebugFileSpec.coffeescript" (gc "..\$_")}
    tools\Nodejs\node.exe tools\CoffeeScript\bin\coffee -c "$OutDebugFileSpec.coffeescript"
}

<#
 Updates the examples to have the latest version of Blackout.
#>
task UpdateExamples -depends Concatenate {
    copy "output\blackout-latest.js" "../examples/regionManager/assets/js/lib/blackout.js"
    copy "output\blackout-latest.js" "../examples/dragndrop/assets/js/lib/blackout.js"
}

<#
 Performs the JavaScript tests using PhantomJs, reporting the results as an NUnit file to be included
 in TeamCity.
#>
task JsTests -depends Concatenate {
    cd $JsTestsFolder    
    &$PhantomJsToolPath "phantomjs_runner.js" "$SpecRunnerPath" "$OutputFolder\test-result.png"
    $TestsFailed = $lastexitcode -ne 0
    
    if ($TestsFailed) {
        throw "JS Tests have failed"
    }

    cd $CurrentFolder
}

task NuGet -depends Concatenate, JsTests {
    $NuspecFile = "Blackout.v$Version.nuspec"
    $NupkgFile = "Blackout.$Version.nupkg"

    [string]::join([environment]::newline, (gc Blackout.nuspec)).Replace('$Version', $Version) | Out-File $NuspecFile -encoding "ascii"

    &.\tools\nuget.exe pack $NuspecFile -OutputDirectory $OutputFolder
    del $NuspecFile
}

task TeamCityBuild -depends Concatenate,JsTests,NuGet
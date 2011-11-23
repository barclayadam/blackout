@echo off
if "%1" == "" goto error

powershell -NoProfile -ExecutionPolicy unrestricted -Command "& {Import-Module '%~dp0\tools\psake\v4.0\psake.psm1'; $psake.use_exit_on_error = $true; invoke-psake '%~dp0\default.ps1' -t %1 -framework 4.0;}"
goto end

:error
echo No parameters have been specified. Syntax is run-build-file BuildStep [Parameter]+ (Parameter = "Key-Value")

:end
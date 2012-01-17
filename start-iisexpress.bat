@set SCRIPT_DIR=%~dp0

"C:\Program Files (x86)\IIS Express\iisexpress.exe" /port:10000 -path:"%SCRIPT_DIR:~0,-1%" /systray:false
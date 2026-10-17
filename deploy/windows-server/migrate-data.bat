@echo off
setlocal
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
if "%~1"=="" (
    echo Usage: migrate-data.bat "D:\old-reader\storage" [InstallDir]
    echo.
    set /p SRC=Source storage path: 
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0migrate-data.ps1" -Source "%SRC%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0migrate-data.ps1" %*
)
echo.
pause

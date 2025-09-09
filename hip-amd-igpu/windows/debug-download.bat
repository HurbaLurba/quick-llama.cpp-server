@echo off
REM Debug script to test the download process specifically

echo HIP LLaMA Download Test
echo ========================

set LLAMA_VERSION=b6423
set DOWNLOAD_URL=https://github.com/ggml-org/llama.cpp/releases/download/%LLAMA_VERSION%/llama-%LLAMA_VERSION%-bin-win-hip-radeon-x64.zip
set ZIP_FILE=llama-%LLAMA_VERSION%-bin-win-hip-radeon-x64.zip

echo URL: %DOWNLOAD_URL%
echo Target file: %ZIP_FILE%
echo.

REM Check if llama-server.exe exists
if exist "llama-server.exe" (
    echo [WARNING] llama-server.exe already exists
    echo Removing it to force fresh download...
    del "llama-server.exe" 2>nul
    if exist "llama-server.exe" (
        echo [ERROR] Could not delete existing llama-server.exe - may be in use
        pause
        exit /b 1
    )
    echo [OK] Removed existing file
)

REM Create temp directory
if exist "temp" rmdir /s /q temp 2>nul
mkdir temp
cd temp

echo.
echo Starting download...
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'Continue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -Verbose}"

if not exist "%ZIP_FILE%" (
    echo [ERROR] Download failed!
    cd ..
    pause
    exit /b 1
)

echo [OK] Download completed
dir "%ZIP_FILE%"

echo.
echo Extracting...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath 'extracted' -Force -Verbose"

echo.
echo Contents of extracted folder:
dir extracted /s /b

echo.
echo Looking for llama-server.exe...
for /r "extracted" %%f in (llama-server.exe) do (
    echo Found: %%f
    echo File size: 
    dir "%%f"
    echo.
    echo Copying to parent directory...
    copy "%%f" "..\llama-server.exe"
    if exist "..\llama-server.exe" (
        echo [OK] Successfully copied llama-server.exe
        cd ..
        echo Final file check:
        dir "llama-server.exe"
        echo.
        echo [SUCCESS] Download and extraction completed!
        pause
        exit /b 0
    ) else (
        echo [ERROR] Copy failed
    )
)

echo [ERROR] llama-server.exe not found in extracted files
echo.
cd ..
pause

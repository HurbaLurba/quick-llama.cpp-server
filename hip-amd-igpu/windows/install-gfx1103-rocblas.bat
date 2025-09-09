@echo off
REM Install gfx1103 rocBLAS librREM Check if file already exists (manual download)
if exist "%ZIP_FILE%" (
    echo [OK] Found existing file: %ZIP_FILE%
    goto extract_file
)

REM Try downloading with PowerShell with better error handling
echo [INFO] Downloading rocBLAS libraries for gfx1103...
echo URL: %DOWNLOAD_URL%
powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing -TimeoutSec 300 } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }"
if errorlevel 1 (
    echo.
    echo [ERROR] Automatic download failed
    echo.
    echo MANUAL DOWNLOAD REQUIRED:
    echo 1. Open browser and go to: %DOWNLOAD_URL%
    echo 2. Save the file as: %ZIP_FILE%
    echo 3. Run this script again
    echo.
    echo Alternative: Download from releases page:
    echo https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU/releases/tag/v0.6.2.4
    echo.
    pause
    exit /b 1
)

:extract_filer AMD 780M GPU
REM Fixes missing TensileLibrary.dat for gfx1103 architecture
setlocal EnableDelayedExpansion

echo.
echo [INFO] Installing gfx1103 rocBLAS libraries for AMD 780M
echo [INFO] Source: likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU
echo [INFO] Target: Missing rocBLAS libraries for gfx1103 architecture

REM Check if we're in the right directory
set BIN_DIR=%~dp0bin
if not exist "%BIN_DIR%\llama-server.exe" (
    echo [ERROR] llama-server.exe not found in bin directory
    echo Please run this from the hip-amd-igpu\windows directory
    exit /b 1
)

REM Check if rocblas directory exists
set ROCBLAS_DIR=%BIN_DIR%\rocblas\library
if not exist "%ROCBLAS_DIR%" (
    echo [ERROR] rocBLAS library directory not found: %ROCBLAS_DIR%
    echo Please ensure llama.cpp HIP build is properly installed
    exit /b 1
)

echo [OK] Found rocBLAS directory: %ROCBLAS_DIR%

REM Download URL for the gfx1103 libraries from releases
set REPO_URL=https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU
REM Use the latest release with HIP SDK 6.2.4 compatible files
set DOWNLOAD_URL=https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU/releases/download/v0.6.2.4/rocm_gfx1103_AMD_780M_phoenix_V5.0_for_hip_sdk_6.2.4.7z
set TEMP_DIR=%TEMP%\gfx1103-rocblas
set ZIP_FILE=%TEMP_DIR%\rocblas-gfx1103.7z

echo.
echo Downloading gfx1103 rocBLAS libraries...
echo Source: %REPO_URL%
echo Target: %ROCBLAS_DIR%

REM Create temp directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

REM Download the ZIP file using PowerShell
echo [INFO] Downloading rocBLAS libraries for gfx1103...
powershell -Command "try { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to download gfx1103 libraries
    echo Please check internet connection and try again
    exit /b 1
)

echo [OK] Downloaded: %ZIP_FILE%

REM Extract the 7z file (requires 7-Zip to be installed)
echo [INFO] Extracting rocBLAS libraries...
where 7z >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 7-Zip not found in PATH
    echo Please install 7-Zip and add it to PATH, or extract manually:
    echo File: %ZIP_FILE%
    echo Target: %TEMP_DIR%
    pause
    exit /b 1
)

7z x "%ZIP_FILE%" -o"%TEMP_DIR%" -y >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to extract 7z file
    exit /b 1
)

echo [OK] Extracted to: %TEMP_DIR%

REM Find the extracted files - should contain library folder and rocblas.dll
set SOURCE_DIR=
for /d %%d in ("%TEMP_DIR%\*") do (
    if exist "%%d\library" (
        set SOURCE_DIR=%%d
        goto found_source
    )
)

REM If no subdirectory with library, check temp dir directly
if exist "%TEMP_DIR%\library" (
    set SOURCE_DIR=%TEMP_DIR%
) else (
    echo [ERROR] Could not locate rocBLAS library files in extracted archive
    echo Expected structure: library folder with gfx1103 files
    dir "%TEMP_DIR%" /s /b
    exit /b 1
)

:found_source
echo [OK] Found rocBLAS files: %SOURCE_DIR%

REM Copy the library folder contents
echo.
echo [INFO] Installing gfx1103 rocBLAS library files...
if exist "%SOURCE_DIR%\library" (
    xcopy "%SOURCE_DIR%\library\*" "%ROCBLAS_DIR%\" /Y /S >nul 2>&1
    if errorlevel 1 (
        echo [ERROR] Failed to copy library files
        exit /b 1
    )
    echo [OK] Library files installed to: %ROCBLAS_DIR%
) else (
    echo [WARNING] No library folder found in source
)

REM Copy rocblas.dll if present
if exist "%SOURCE_DIR%\rocblas.dll" (
    echo [INFO] Installing gfx1103 rocblas.dll...
    copy "%SOURCE_DIR%\rocblas.dll" "%BIN_DIR%\rocblas.dll" /Y >nul 2>&1
    if errorlevel 1 (
        echo [WARNING] Failed to copy rocblas.dll - may not be needed
    ) else (
        echo [OK] rocblas.dll updated
    )
) else (
    echo [INFO] No rocblas.dll found - using existing one
)

REM Clean up temp files
echo [INFO] Cleaning up temporary files...
rd /s /q "%TEMP_DIR%" >nul 2>&1

REM Verify installation
echo.
echo [INFO] Verifying gfx1103 library installation...
if exist "%ROCBLAS_DIR%\*gfx1103*" (
    echo [OK] gfx1103 libraries installed successfully:
    dir /b "%ROCBLAS_DIR%\*gfx1103*"
) else (
    echo [WARNING] No gfx1103-specific files found after installation
    echo [INFO] Available library files:
    dir /b "%ROCBLAS_DIR%\TensileLibrary*" 2>nul
)

echo.
echo [INFO] Installation complete!
echo [INFO] You can now try running your HIP-accelerated llama.cpp server
echo [INFO] The missing TensileLibrary.dat error should be resolved

pause

@echo off
REM Install gfx1103 rocBLAS libraries for AMD 780M GPU
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

REM Download URL for the gfx1103 libraries
set REPO_URL=https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU
set DOWNLOAD_URL=https://github.com/likelovewant/ROCmLibs-for-gfx1103-AMD780M-APU/archive/refs/heads/main.zip
set TEMP_DIR=%TEMP%\gfx1103-rocblas
set ZIP_FILE=%TEMP_DIR%\rocblas-gfx1103.zip

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

REM Extract the ZIP file
echo [INFO] Extracting rocBLAS libraries...
powershell -Command "try { Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%' -Force } catch { Write-Error $_.Exception.Message; exit 1 }"
if errorlevel 1 (
    echo [ERROR] Failed to extract ZIP file
    exit /b 1
)

echo [OK] Extracted to: %TEMP_DIR%

REM Find the extracted directory (should be ROCmLibs-for-gfx1103-AMD780M-APU-main)
set EXTRACTED_DIR=%TEMP_DIR%\ROCmLibs-for-gfx1103-AMD780M-APU-main

if not exist "%EXTRACTED_DIR%" (
    echo [ERROR] Extracted directory not found: %EXTRACTED_DIR%
    echo Archive structure may have changed
    exit /b 1
)

echo [OK] Found extracted files: %EXTRACTED_DIR%

REM Look for rocBLAS library files in the extracted directory
REM The repo structure might have rocblas/library subdirectory
set SOURCE_ROCBLAS_DIR=
if exist "%EXTRACTED_DIR%\rocblas\library" (
    set SOURCE_ROCBLAS_DIR=%EXTRACTED_DIR%\rocblas\library
) else if exist "%EXTRACTED_DIR%\library" (
    set SOURCE_ROCBLAS_DIR=%EXTRACTED_DIR%\library
) else (
    REM Try to find any directory with .dat or .hsaco files
    for /f "delims=" %%d in ('dir /s /b "%EXTRACTED_DIR%\*.dat" 2^>nul ^| head -1') do (
        set SOURCE_ROCBLAS_DIR=%%~dpd
    )
)

if not defined SOURCE_ROCBLAS_DIR (
    echo [ERROR] Could not locate rocBLAS library files in extracted archive
    echo Please check the repository structure at: %REPO_URL%
    exit /b 1
)

echo [OK] Found rocBLAS source files: %SOURCE_ROCBLAS_DIR%

REM List what we're about to copy
echo.
echo Files to install for gfx1103:
dir /b "%SOURCE_ROCBLAS_DIR%\*gfx1103*" 2>nul
if errorlevel 1 (
    echo [WARNING] No gfx1103-specific files found, looking for generic files...
    dir /b "%SOURCE_ROCBLAS_DIR%\*.dat" "%SOURCE_ROCBLAS_DIR%\*.hsaco" 2>nul
)

REM Copy gfx1103-specific files
echo.
echo [INFO] Installing gfx1103 rocBLAS libraries...
xcopy "%SOURCE_ROCBLAS_DIR%\*gfx1103*" "%ROCBLAS_DIR%\" /Y >nul 2>&1
if errorlevel 1 (
    echo [WARNING] No gfx1103-specific files found, copying all library files...
    xcopy "%SOURCE_ROCBLAS_DIR%\*.dat" "%ROCBLAS_DIR%\" /Y >nul 2>&1
    xcopy "%SOURCE_ROCBLAS_DIR%\*.hsaco" "%ROCBLAS_DIR%\" /Y >nul 2>&1
    xcopy "%SOURCE_ROCBLAS_DIR%\*.co" "%ROCBLAS_DIR%\" /Y >nul 2>&1
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

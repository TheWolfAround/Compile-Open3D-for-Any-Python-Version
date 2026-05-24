@echo off
@if not defined DevEnvDir (
    set "InstalledVSPath="
    set "VsWherePath="

    setlocal enabledelayedexpansion

    @if exist "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VsWherePath=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    )

    @if exist "C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe" (
        set "VsWherePath=C:\Program Files\Microsoft Visual Studio\Installer\vswhere.exe"
    )

    if not defined VsWherePath (
        echo.
        echo #############################################################
        echo No Visual-Studio or VS-Build-Tools installation was detected.
        echo #############################################################
        exit /b 1
    )

    for /f "usebackq tokens=*" %%i in (
        `"!VsWherePath!" -products * -latest -property installationPath`
    ) do set "InstalledVSPath=%%i"

    if defined InstalledVSPath (
        if exist "!InstalledVSPath!\VC\Auxiliary\Build\vcvarsall.bat" (
            call "!InstalledVSPath!\VC\Auxiliary\Build\vcvarsall.bat" x64
        ) else (
            echo.
            echo ################################
            echo Error: vcvarsall.bat not found.
            echo ################################
            exit /b 1
        )
    ) else (
        echo.
        echo #############################################################
        echo No Visual-Studio or VS-Build-Tools installation was detected.
        echo #############################################################
        exit /b 1
    )
)

echo.
@echo off
where git >nul 2>&1
if %errorlevel% equ 1 (
    echo.
    echo #####################################################################################
    echo WARNING!
    echo   - Git is not installed.
    echo   - Git is required to download the source code for Vulkan libraries in this script.
    echo   - To install Git on Windows, visit the link below and download it:
    echo   - Download Link: https://git-scm.com/downloads
    echo   - Quitting.
    echo #####################################################################################
    echo.
    exit /b 1
) else (
    for /f "delims=" %%i in ('where git') do (
        set "git_path=%%i"
        goto :git_done
    )
    :git_done
    echo.
    echo ###############################################################################
    echo Git is already installed. Installation dir: "%git_path%"
    echo ###############################################################################
    echo.
)

@if not exist "%cd%\Compile-Vulkan-Equipments-on-Windows" (
    git clone --depth 1 git@github.com:TheWolfAround/Compile-Vulkan-Equipments-on-Windows.git --recursive
) else (
    echo.
    echo ###########################################################
    echo Compile-Vulkan-Equipments-on-Windows folder already exists.
    echo ###########################################################
    echo.
)

@if not exist "%cd%\Open3D" (
    git clone --depth 1 https://github.com/isl-org/Open3D.git --recursive
) else (
    echo.
    echo #############################
    echo Open3D folder already exists.
    echo #############################
    echo.
)

@if not exist "%cd%\Compile-Vulkan-Equipments-on-Windows\__build_out__\Release\__glslang__\bin\glslangValidator.exe" (
    echo.
    echo #####################################################################################
    echo * WARNING!
    echo   - "glslangValidator.exe" not found!
    echo   - First run the compilation script inside the .\Compile-Vulkan-Equipments-on-Windows
    echo     using 'Ninja' Cmake Genrator Option.
    echo #####################################################################################
    echo.
    exit /b 1
)

set "PROC=%NUMBER_OF_PROCESSORS%"

if %PROC% GTR 12 (
    set "NUM_THREADS=6"
) else if %PROC% GEQ 8 (
    set "NUM_THREADS=4"
) else if %PROC% GEQ 4 (
    set "NUM_THREADS=2"
) else (
    set "NUM_THREADS=1"
)

echo.
echo #############################
echo Compilation parallel jobs: %NUM_THREADS%
echo #############################
echo.

set BUILD_OUT_DIR=%cd%\__build_out__
set BUILD_DIR=%cd%\__build_dir__

rmdir /s /q %BUILD_DIR%

cmake -G Ninja ^
    -D CMAKE_BUILD_TYPE=Release ^
    -D CMAKE_INSTALL_PREFIX=%BUILD_OUT_DIR% ^
    -D BUILD_PYTHON_MODULE=ON ^
    -D STATIC_WINDOWS_RUNTIME=OFF ^
    -D OPEN3D_GLSLANG_VALIDATOR="%cd%\Compile-Vulkan-Equipments-on-Windows\__build_out__\Release\__glslang__\bin\glslangValidator.exe" ^
    -D BUILD_WEBRTC=OFF ^
    -S %cd%\Open3D ^
    -B %BUILD_DIR%

cmake --build %BUILD_DIR% --config Release --target install -j%NUM_THREADS%
cmake --build %BUILD_DIR% --config Release --target pip-package

xcopy "%cd%\__build_dir__\lib\python_package\pip_package" "%cd%" /E /I /Y

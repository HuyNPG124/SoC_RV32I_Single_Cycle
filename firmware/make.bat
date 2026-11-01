@echo off
setlocal

set "PATH=C:\msys64\usr\bin;C:\msys64\ucrt64\bin;%PATH%"
set "RISCV_TOOLCHAIN_DIR=C:/msys64/ucrt64/bin"
set "PYTHON=C:/Python314/python.exe"

if not exist "C:\msys64\usr\bin\make.exe" (
    echo ERROR: GNU Make was not found at C:\msys64\usr\bin\make.exe
    exit /b 1
)

"C:\msys64\usr\bin\make.exe" %* RISCV_TOOLCHAIN_DIR=%RISCV_TOOLCHAIN_DIR% PYTHON=%PYTHON%
exit /b %ERRORLEVEL%

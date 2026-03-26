@echo off
REM Set up environment variables
SET GCC_TYPE=gcc121
SET OS_BUILD=64

IF "%GCC_TYPE%" == "gcc121" (set GCC_TYPE=)
set WD=C:\ming%OS_BUILD%%GCC_TYPE%\msys\usr\bin\
set MSYSTEM=MINGW%OS_BUILD%
PATH=C:\ming%OS_BUILD%%GCC_TYPE%\msys\bin\;C:\ming%OS_BUILD%%GCC_TYPE%\msys\usr\bin\;%PATH%

REM Debugging: Print environment variables
echo "WD: %WD%"
echo "MSYSTEM: %MSYSTEM%"
echo "PATH: %PATH%"

REM Check if the script path and parameters are provided
IF "%~1"=="" (
    echo Usage: run_msys2.bat <script_path> [parameters...]
    exit /b 1
)

REM Run the shell script with parameters passed from the batch script
bash --login -c '"%~1" %*'

REM Exit with the same code returned by bash command
exit /b %ERRORLEVEL%

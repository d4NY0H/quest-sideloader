@echo OFF
:: --- v1.0.2021 by d4NY0 ---
set TITLE=Quest-Sideloader
TITLE %TITLE%

:: Set official platform tools download url.
set PTURL="https://dl.google.com/android/repository/platform-tools-latest-windows.zip"

:: Set the path to the folder containing the adb.exe.
set DOCDIR=%USERPROFILE%\Documents
set ADBDIR=%DOCDIR%\platform-tools

:: Check for platform-tools dir and required adb files.
if not exist %ADBDIR%\ goto DirError
if not exist %ADBDIR%\adb.exe goto DirError
if not exist %ADBDIR%\AdbWinApi.dll goto DirError
if not exist %ADBDIR%\AdbWinUsbApi.dll goto DirError

:: Add adb dir to path variable.
set PATH=%PATH%;%ADBDIR%\

:: apk is required.
if not exist *.apk goto Empty

:: Wait until device is connected.
echo Waiting for the device.
adb wait-for-device

:: Get device informations.
echo Querying device information.
for /f "tokens=9" %%a in ('adb shell ip route') do (set ipaddrt=%%a)
for /f "tokens=1,2" %%i in ('adb shell dumpsys battery') do ^if "%%i"=="level:" set LVL=%%j
for /f "tokens=4" %%i in ('adb shell df -h /data/media') do set STG=%%i
:: Update the title.
TITLE %TITLE%-Connected-[Battery:%LVL%]-[IP:%ipaddrt%]-[Free space %STG%]

:: Show devices.
adb devices

:: Check for install.txt
@if exist install.txt goto txt

:: Install every apk in this folder.
for /f "delims=|" %%i in ('dir /b "*.apk"') do (
	echo Installing %%~ni.apk
	adb install -g -r "%%i"
)

:: Copy each folder to obb directory.
for /d %%d in (*.*) do (
	@echo Copy obb folder %%d to /sdcard/Android/obb/
	adb push %%d /sdcard/Android/obb/%%d/
)
@if "%ERRORLEVEL%" NEQ "0" (goto Error) else (goto Success)

:txt
:: Execute each line inside install.txt.
echo Execute install.txt:
FOR /F "USEBACKQ TOKENS=*" %%A IN (install.txt) do (
    cmd /c "%%~A"
)
@if "%ERRORLEVEL%" NEQ "0" (goto Error) else (goto Success)

:Success
@echo [92mInstallation successful.[0m
@pause
goto Quit

:Error
@echo [91mError installing the APK or the obb file.[0m
@pause
goto Quit

:Empty
@echo [91mNo apk file found in this folder.[0m
@pause
goto Quit

:DirError
@echo [91mError! The required ADB files could not be found:[0m
@echo %ADBDIR%\adb.exe
@echo %ADBDIR%\AdbWinApi.dll
@echo %ADBDIR%\AdbWinUsbApi.dll
@echo(
@echo Download from %PTURL%
@echo(
set /p INPUT=Do you want to download it now? [y/n] 
IF /I '%INPUT%'=='y' GOTO Download
IF /I '%INPUT%'=='n' GOTO Quit

:Download
@echo(
:: Download platform tools with curl.
curl --ssl-no-revoke -L "%PTURL%" -o "%DOCDIR%\platform-tools-latest-windows.zip"
:: Unpack zip with powershell.
powershell -Command "Expand-Archive -Force '%DOCDIR%\platform-tools-latest-windows.zip' -DestinationPath '%DOCDIR%'"
:: Delete zip file.
del /q %DOCDIR%\platform-tools-latest-windows.zip
@echo(
@echo [92mSucessfully downloaded the neccessary files.[0m
@echo(
timeout 1 >nul
:: Reload this script.
call "%~f0"
goto Quit

:Quit
adb kill-server
exit
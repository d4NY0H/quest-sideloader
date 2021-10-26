@echo OFF
for /d %%I in (*) do xcopy "install.bat" "%%~fsI" /H /K /Y /D
@pause
exit
xcopy %~d0\windows-guest\* C:\triton\bin /s /i /y
rem copy will not create its destination directory, and Server 2025 has no Setup\Scripts by default.
if not exist C:\Windows\Setup\Scripts mkdir C:\Windows\Setup\Scripts
if errorlevel 1 exit /b 1
copy C:\triton\bin\SetupComplete.cmd C:\Windows\Setup\Scripts\SetupComplete.cmd /Y
if errorlevel 1 exit /b 1
exit /b 0

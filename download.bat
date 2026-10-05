@echo off
setlocal

rem === CHANGE THESE. Keep them identical on every run so aria2 can resume. ===
set "DIR=%USERPROFILE%\Downloads\Server"
set "NAME=bigfile.tar.gz"

if not exist "%DIR%" mkdir "%DIR%"

:loop
echo.
set "URL="
set /p "URL=Paste FRESH signed URL and press Enter: "
if not defined URL goto loop

echo.
echo --- Range test (want HTTP/1.1 206 and a Content-Range line) ---
curl.exe -s -D - -r 0-0 -o NUL "%URL%" | findstr /i /b "HTTP/ Content-Range Accept-Ranges ETag Last-Modified"
echo ---------------------------------------------------------------
echo.

aria2c -c -x 16 -s 16 -k 1M ^
  --file-allocation=none --auto-file-renaming=false --allow-overwrite=false ^
  --max-tries=2 --retry-wait=1 --timeout=30 --connect-timeout=10 ^
  --summary-interval=30 ^
  -d "%DIR%" -o "%NAME%" "%URL%"

if %ERRORLEVEL%==0 goto done

echo.
echo aria2 stopped (exit code %ERRORLEVEL%). Generate a NEW link in the panel and paste it.
goto loop

:done
echo.
echo Download complete.
pause

@echo off
setlocal enabledelayedexpansion
:: 设置代码页为UTF (65001)
chcp 65001 > nul
color 02
set "configFile=.ini"

set "proxy=https://ghp.ci/"
set "version_url=https://raw.githubusercontent.com/lumuzhi/config/main/version"
set "update_url=https://raw.githubusercontent.com/lumuzhi/config/main/singbox.cmd"
set "unix2dos_url=https://github.com/lumuzhi/config/blob/main/unix2dos.exe"

for /f "tokens=1,2 delims==" %%a in (%configFile%) do (
    if "%%a"=="version" set "version=%%b"
    if "%%a"=="country" set "country=%%b"
)

if "!country!"=="CN" (
    set "version_url=%proxy%%version_url%"
    set "update_url=%proxy%%update_url%"
    set "unix2dos_url=%proxy%%unix2dos_url%"
    set "v=%proxy%%v%"
)

for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri '!version_url!'"') do set "remoteVersion=%%a"
if not exist unix2dos.exe (
    powershell -NoProfile -Command "Try { Invoke-RestMethod -Uri '%unix2dos_url%' -OutFile 'unix2dos.exe' } Catch { Write-Host 'unix2dos下载失败: $_' }"
)
curl -sL %update_url% > temp.cmd
if %errorlevel% neq 0 (
    echo 获取脚本内容失败
    exit
)
for /f "delims=" %%i in (temp.cmd) do set content=%%i
if not defined content (
    echo 无效的更新数据
    exit
)
move /y temp.cmd singbox.cmd > nul
:: curl -sL %update_url% > singbox.cmd
unix2dos.exe singbox.cmd singbox.cmd

for /f "tokens=1,* delims==" %%a in (%configFile%) do (
    if "%%a"=="version" (
        echo version=!remoteVersion!>temp
    ) else (
        echo %%a=%%b>>temp
    )
)
del %configFile%
ren temp %configFile%
start "" "singbox.cmd"

exit
endlocal

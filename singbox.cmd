@echo off
setlocal enabledelayedexpansion
:: 设置代码页为UTF (65001)
chcp 65001 > nul
color 02

:: 检查是否以管理员权限运行
:: net session >nul 2>&1
:: if %errorlevel% neq 0 (
::     echo 请以管理员权限运行此脚本。
::     pause
::     exit /b
:: )


set "proxy=https://ghp.ci/"
set "sfw_url=https://github.com/lumuzhi/config/blob/main/sfw.zip"
set "singbox_url=https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip"
set "version_url=https://raw.githubusercontent.com/lumuzhi/config/main/version"
set "update_url=https://raw.githubusercontent.com/lumuzhi/config/main/singbox.cmd"
set "update_script=https://raw.githubusercontent.com/lumuzhi/config/main/update.cmd"
set "unix2dos_url=https://github.com/lumuzhi/config/blob/main/unix2dos.exe"
set "v=https://raw.githubusercontent.com/lumuzhi/config/main/v"

set "localVersion="
set "country="
set "remoteVersion="
set "configFile=.ini"
set "curr_dir=%CD%"
set "mypath=%PATH%"


if exist update.cmd (
    del update.cmd
)
if not exist !configFile! (
    :: 输出默认配置文件
    echo version=^1>%configFile%
    for /f "delims=" %%a in ('powershell -command "try { $result = Invoke-RestMethod -Uri 'https://ipget.net/country'; if ($result -match '^[A-Z]{2}$') { $result } else { 'CN' } } catch { 'CN' }"') do (
        set country=%%a
    )
)
if not defined country (
    set "country=CN"
)
echo country=!country!>>%configFile%
call :getConfigInfo

if "!country!"=="CN" (
    set "sfw_url=%proxy%%sfw_url%"
    set "singbox_url=%proxy%%singbox_url%"
    set "version_url=%proxy%%version_url%"
    set "update_url=%proxy%%update_url%"
    set "update_script=%proxy%%update_script%"
    set "unix2dos_url=%proxy%%unix2dos_url%"
    set "v=%proxy%%v%"
)
:: 获取最新的版本号
for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri '!version_url!'"') do set "remoteVersion=%%a"
:: echo %mypath% | findstr /C:"%curr_dir%" > nul
:: if %errorlevel% neq 0 (
::     echo 首次安装设置环境
::     setx PATH "%mypath%;%curr_dir%"
::     echo 关闭该窗口重新打开
::     pause
::     exit
:: )



:: 菜单选项
:menu
echo 当前版本：!localVersion! 所在国家：!country!
echo.
echo 1.全局代理：tun模式
echo 2.本地代理：支持http，socks
if !remoteVersion! gtr !localVersion! (
    echo 3.更新脚本^(可用更新版本:!remoteVersion!,选择3进行更新^)
    echo ----------------------------------------------------
    echo 更新内容：
    for /f "delims=" %%a in ('powershell -command "try { Invoke-RestMethod -Uri '!v!' } catch { Write-Host $_.Exception.Message; exit 1 }"') do echo %%a
    echo ----------------------------------------------------
) else (
    echo 3.更新脚本^(当前为最新^)
)
echo 0.退出脚本
echo.
set "choice="
set /p choice="选择："

if "!choice!"=="1" goto tunMode
if "!choice!"=="2" goto localMode
if "!choice!"=="3" goto update
if "!choice!"=="0" exit

:getConfigInfo

for /f "tokens=1,2 delims==" %%a in (%configFile%) do (
    if "%%a"=="version" set "localVersion=%%b"
    if "%%a"=="country" set "country=%%b"
)
goto :EOF

:tunMode
cls
if not exist sfw (
    mkdir sfw
    powershell -command "Invoke-RestMethod -Uri '!sfw_url!'" -OutFile sfw\sfw.zip
    if not exist sfw\sfw.zip (
        echo sfw.zip下载失败
        pause
        exit /b
    )
    tar -xf sfw\sfw.zip -C sfw
    del sfw\sfw.zip
)
curl -sL "https://sbox.linwanrong.com/sfw" > sfw\config.json
start cmd /k "cd /d "%curr_dir%\sfw" && powershell -Command "Start-Process 'SFW.exe' -Verb RunAs" && exit"
exit


:localMode
cls
if not exist sb (
    mkdir sb
    powershell -command "Invoke-RestMethod -Uri '!singbox_url!'" -OutFile sb\singbox.zip
    if not exist sb\singbox.zip (
        echo singbox.zip下载失败
        pause
        exit
    )
    tar -xf sb\singbox.zip -C sb
    move sb\sing-box-* sb\sing-box > nul
    move sb\sing-box\sing-box.exe sb > nul
    rmdir /s /q sb\sing-box
    del sb\singbox.zip
)
:: call :createConfig "https://sbox.linwanrong.com"

curl -sL "https://sbox.linwanrong.com" > sb\config.json
start cmd.exe /k "cd /d %curr_dir%\sb && sing-box.exe run"
:: sb\sing-box.exe run -c sb\config.json
exit



:update
cls
:: powershell -command "Invoke-RestMethod -Uri '!update!'" -OutFile update.cmd
powershell -NoProfile -Command "Try { Invoke-RestMethod -Uri '%update_script%' -OutFile 'update.cmd' } Catch { Write-Host '更新脚本下载失败: $_' }"
if not exist unix2dos.exe (
    powershell -NoProfile -Command "Try { Invoke-RestMethod -Uri '%unix2dos_url%' -OutFile 'unix2dos.exe' } Catch { Write-Host 'unix2dos下载失败: $_' }"
)
unix2dos.exe update.cmd update.cmd
start "" "update.cmd"
exit


:createConfig
setlocal
set "url=%~1"
set "path=%~2"
:: 使用 curl 获取 URL 内容并写入到指定路径
curl -sL "%url%" -o "%path%"
if %errorlevel% neq 0 (
    echo 从 !url! 获取 JSON 数据失败
    endlocal
    exit /b
)
goto :EOF



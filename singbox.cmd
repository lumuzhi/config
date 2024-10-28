@echo off
setlocal enabledelayedexpansion
:: 设置代码页为UTF (65001)
chcp 65001 > nul

set proxy=https://ghp.ci/
set sfw_url=https://github.com/lumuzhi/config/blob/main/sfw.zip
set singbox_url=https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip
set version_url=https://raw.githubusercontent.com/lumuzhi/config/main/version
set update_url=https://raw.githubusercontent.com/lumuzhi/config/main/singbox.cmd
set unix2dos_url=https://github.com/lumuzhi/config/blob/main/unix2dos.exe

if not exist country (
    :: 使用PowerShell获取国家信息
    for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'http://ipinfo.io/country'"') do set country=%%a
    echo !country!>country
) else (
    set country=
    for /f "delims=" %%i in (country) do (
        set country=%%i
    )
)
if not exist version (
    for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri '%proxy%%version_url%'"') do set updateversion=%%a
    echo !updateversion!>version
) else (
    set version=
    for /f "delims=" %%i in (version) do (
        set version=%%i
    )
)

for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri '%proxy%%version_url%'"') do set updateversion=%%a
if !updateversion! gtr %version% (
	echo 脚本已更新至版本：!updateversion!，选择3进行更新
)

if not exist unix2dos.exe (
    if "!country!"=="CN" (
	    powershell -command "Invoke-WebRequest -Uri '%proxy%%unix2dos_url%' -OutFile 'unix2dos.exe'"
	) else (
	    powershell -command "Invoke-WebRequest -Uri '%unix2dos_url%' -OutFile 'unix2dos.exe'"
	)
)
:menu
echo ----------------------当前版本：%version% (仅支持window)-----------------------------
echo 全局代理：tun模式
echo 本地代理：支持http，socks
echo -----------------------------------------------------------------------------------
echo note: 
echo 1.建议选择本地代理
echo 2.网页打开慢？，重新运行脚本更新配置文件 3.如果写入较慢，关闭窗口，删掉生成的文件重新运行
echo -----------------------------------------------------------------------------------
@REM cls
echo.
echo 1. 全局代理
echo 2. 本地代理
echo 3. 更新脚本
echo 0. 退出脚本
echo.

set choice=
set /p choice="选择模式：" 

if /i "%choice%"=="1" goto tunmode
if /i "%choice%"=="2" goto localmode
if /i "%choice%"=="3" goto updatescript
if /i "%choice%"=="0" goto exitscript

:tunmode
cls
if not exist SFW.exe (
    echo 准备下载sfw.zip
	if "%country%"=="CN" (
	    powershell -command "Invoke-WebRequest -Uri 'https://ghp.ci/https://github.com/lumuzhi/config/blob/main/sfw.zip' -OutFile 'sfw.zip'"
	) else (
	    powershell -command "Invoke-WebRequest -Uri '%sfw_url%' -OutFile 'sfw.zip'"
	)
    if exist sfw.zip (
        tar -xf sfw.zip
        @REM move sing-box-1.10.1-windows-amd64\sing-box.exe .\
        @REM rmdir /s /q sing-box-1.10.1-windows-amd64
        del sfw.zip
    ) else (
        echo sfw.zip下载失败
        goto exitscript
    )
)

:: 定义 URL 和文件路径
set url=https://sbox.linwanrong.com/sfw
set filePath=config.json

:: 使用 curl 获取 JSON 数据
curl -sL %url% > temp.json

:: 检查 curl 是否成功执行
if %errorlevel% neq 0 (
    echo 无法从服务器获取 JSON 数据。
    exit /b 1
)

:: 检查 JSON 数据是否为空
for /f "delims=" %%i in (temp.json) do set jsonContent=%%i

if not defined jsonContent (
    echo 没有从服务器获取到有效的 JSON 数据。
    del temp.json
    exit /b 1
)

:: 将 JSON 数据写入 config.json
move /y temp.json %filePath% > nul

:: 使用 PowerShell 启动 EXE 并以管理员权限运行
powershell -Command "Start-Process SFW -Verb RunAs"
exit

:localmode
cls
if not exist sing-box.exe (
    echo 准备下载singbox
	if "!country!"=="CN" (
	    powershell -command "Invoke-WebRequest -Uri '%proxy%%singbox_url%' -OutFile 'sing-box.zip'"
	) else (
	    powershell -command "Invoke-WebRequest -Uri '%singbox_url%' -OutFile 'sing-box.zip'"
	)
    if exist sing-box.zip (
        tar -xf sing-box.zip
        move sing-box\sing-box.exe .\ > nul
        rmdir /s /q sing-box
        del *.zip
    ) else (
        echo singbox下载失败
        goto exitscript
    )
)

:: 定义 URL 和文件路径
set url=https://sbox.linwanrong.com
set filePath=config.json

:: 使用 curl 获取 JSON 数据
curl -sL %url% > temp.json

:: 检查 curl 是否成功执行
if %errorlevel% neq 0 (
    echo 无法从服务器获取 JSON 数据。
    exit /b 1
)

:: 检查 JSON 数据是否为空
for /f "delims=" %%i in (temp.json) do set jsonContent=%%i

if not defined jsonContent (
    echo 没有从服务器获取到有效的 JSON 数据。
    del temp.json
    exit /b 1
)

:: 将 JSON 数据写入 config.json
move /y temp.json %filePath% > nul

:: 执行 singbox run 命令
sing-box.exe run


:updatescript
set filePath=singbox.cmd
cls
if "!country!"=="CN" (
	powershell -command "Invoke-WebRequest -Uri '%proxy%%update_url%' -OutFile 'new.cmd'"
) else (
	powershell -command "Invoke-WebRequest -Uri '%update_url%' -OutFile 'new.cmd'"
)

if exist new.cmd (
    unix2dos.exe new.cmd new.cmd
    echo !updateversion!>version
)

REM 更新脚本
if not exist end.cmd (
    echo @echo off > end.cmd
    echo chcp 65001 ^> nul >> end.cmd
    echo timeout /t 1 ^> nul >> end.cmd
    echo del singbox.cmd ^> nul >> end.cmd
    echo move /y new.cmd %filePath% ^> nul >> end.cmd
    echo echo 更新成功 >> end.cmd
    echo pause >> end.cmd
)

start end.cmd
exit

:exitscript
pause
exit

endlocal

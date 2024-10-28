@echo off
setlocal
setlocal enabledelayedexpansion
:: 设置代码页为UTF (65001)
chcp 65001 > nul


set version=
for /f "delims=" %%i in (version) do (
	set version=%%i
)

for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'https://ghp.ci/https://raw.githubusercontent.com/lumuzhi/config/main/version'"') do set updateversion=%%a
if %updateversion% gtr %version% (
	echo 脚本已更新至版本：!updateversion!，选择3进行更新
)


:menu
echo ----------------------当前版本：!version!----------------------------
echo 全局代理：tun模式
echo 本地代理：支持http，socks
echo --------------------------------------------------
echo note: 
echo 1.建议选择本地代理
echo 2.网页打开慢？，重新运行脚本更新配置文件 3.如果写入较慢，关闭窗口，删掉生成的文件重新运行
echo --------------------------------------------------
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
:: 使用PowerShell获取国家信息
for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'http://ipinfo.io/country'"') do set country=%%a

cls
if not exist SFW.exe (
	if "!country!"=="CN" (
	    cd %USERPROFILE%
	    powershell -command "Invoke-WebRequest -Uri 'https://ghp.ci/https://github.com/lumuzhi/config/blob/main/sfw.zip' -OutFile 'sfw.zip'") else (
	    cd %USERPROFILE%
	    powershell -command "Invoke-WebRequest -Uri 'https://github.com/lumuzhi/config/blob/main/sfw.zip' -OutFile 'sfw.zip'"
	)

	tar -xf sfw.zip
	@REM move sing-box-1.10.1-windows-amd64\sing-box.exe .\
	@REM rmdir /s /q sing-box-1.10.1-windows-amd64
	del sfw.zip
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
:: 使用PowerShell获取国家信息
for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'http://ipinfo.io/country'"') do set country=%%a

cls
if not exist sing-box.exe (
	if "!country!"=="CN" (
	    cd %USERPROFILE%
	    powershell -command "Invoke-WebRequest -Uri 'https://ghp.ci/https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip' -OutFile 'sing-box-1.10.1-windows-amd64.zip'") else (
	    cd %USERPROFILE%
	    powershell -command "Invoke-WebRequest -Uri 'https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip' -OutFile 'sing-box-1.10.1-windows-amd64.zip'"
	)

	tar -xf sing-box-1.10.1-windows-amd64.zip
	move sing-box-1.10.1-windows-amd64\sing-box.exe .\ > nul
	rmdir /s /q sing-box-1.10.1-windows-amd64
	del *.zip
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
for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'http://ipinfo.io/country'"') do set country=%%a
cls
if "!country!"=="CN" (
	cd %USERPROFILE%
	powershell -command "Invoke-WebRequest -Uri 'https://ghp.ci/https://raw.githubusercontent.com/lumuzhi/config/main/singbox.cmd' -OutFile 'temp.cmd'") else (
	cd %USERPROFILE%
	powershell -command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/lumuzhi/config/main/singbox.cmd' -OutFile 'temp.cmd'"
)
move /y temp.cmd %filePath% > nul
move /y !updateversion! version > nul
echo 更新成功
goto menu

:exitscript
pause
exit


@REM :sh_download
@REM :: 使用PowerShell获取国家信息
@REM for /f "delims=" %%a in ('powershell -command "Invoke-RestMethod -Uri 'http://ipinfo.io/country'"') do set country=%%a

@REM :: 检查是否是中国
@REM if not exist sing-box.exe (
@REM 	if "!country!"=="CN" (
@REM 	    cd %USERPROFILE%
@REM 	    powershell -command "Invoke-WebRequest -Uri 'https://ghp.ci/https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip' -OutFile 'sing-box-1.10.1-windows-amd64.zip'") else (
@REM 	    cd %USERPROFILE%
@REM 	    powershell -command "Invoke-WebRequest -Uri 'https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-windows-amd64.zip' -OutFile 'sing-box-1.10.1-windows-amd64.zip'"
@REM 	)

@REM 	tar -xf sing-box-1.10.1-windows-amd64.zip
@REM 	move sing-box-1.10.1-windows-amd64\sing-box.exe .\ > nul
@REM 	rmdir /s /q sing-box-1.10.1-windows-amd64
@REM 	del *.zip
@REM )

@REM :: 定义 URL 和文件路径
@REM set url=https://sbox.linwanrong.com
@REM set filePath=config.json

@REM :: 使用 curl 获取 JSON 数据
@REM curl -sL %url% > temp.json

@REM :: 检查 curl 是否成功执行
@REM if %errorlevel% neq 0 (
@REM     echo 无法从服务器获取 JSON 数据。
@REM     exit /b 1
@REM )

@REM :: 检查 JSON 数据是否为空
@REM for /f "delims=" %%i in (temp.json) do set jsonContent=%%i

@REM if not defined jsonContent (
@REM     echo 没有从服务器获取到有效的 JSON 数据。
@REM     del temp.json
@REM     exit /b 1
@REM )

@REM :: 将 JSON 数据写入 config.json
@REM move /y temp.json %filePath% > nul

@REM :: 执行 singbox run 命令
@REM sing-box.exe run

endlocal

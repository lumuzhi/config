#!/bin/bash
export LANG=en_US.UTF-8
# red='\033[0;31m'
# green='\033[0;32m'
# yellow='\033[0;33m'
# blue='\033[0;36m'
# bblue='\033[0;34m'
# plain='\033[0m'
red(){ echo -e "\033[31m\033[01m$1\033[0m";}
green(){ echo -e "\033[32m\033[01m$1\033[0m";}
yellow(){ echo -e "\033[33m\033[01m$1\033[0m";}
blue(){ echo -e "\033[36m\033[01m$1\033[0m";}
white(){ echo -e "\033[37m\033[01m$1\033[0m";}
readp(){ read -p "$(yellow "$1")" $2;}

[[ $EUID -ne 0 ]] && yellow "请以root模式运行脚本" && exit

if [[ -f /etc/redhat-release ]]; then
    release="Centos"
elif cat /etc/issue | grep -q -E -i "alpine"; then
    release="alpine"
elif cat /etc/issue | grep -q -E -i "debian"; then
    release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
    release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
    release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
    release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
    release="Centos"
else 
    red "脚本不支持当前的系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi

vsid=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)
op=$(cat /etc/redhat-release 2>/dev/null || cat /etc/os-release 2>/dev/null | grep -i pretty_name | cut -d \" -f2)
#if [[ $(echo "$op" | grep -i -E "arch|alpine") ]]; then
if [[ $(echo "$op" | grep -i -E "arch") ]]; then
red "脚本不支持当前的 $op 系统，请选择使用Ubuntu,Debian,Centos系统。" && exit
fi
version=$(uname -r | cut -d "-" -f1)
[[ -z $(systemd-detect-virt 2>/dev/null) ]] && vi=$(virt-what 2>/dev/null) || vi=$(systemd-detect-virt 2>/dev/null)
case $(uname -m) in
    aarch64) cpu=arm64;;
    x86_64) cpu=amd64;;
        *) red "目前脚本不支持$(uname -m)架构" && exit;;
esac

if [[ -n $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk -F ' ' '{print $3}') ]]; then
    bbr=`sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}'`
elif [[ -n $(ping 10.0.0.2 -c 2 | grep ttl) ]]; then
    bbr="Openvz版bbr-plus"
else
    bbr="Openvz/Lxc"
fi
hostname=$(hostname)

gh_proxy=https://ghp.ci/
sfw_download_url=https://github.com/lumuzhi/config/blob/main/sfw.zip
version_download_url=https://raw.githubusercontent.com/lumuzhi/config/main/version
unix2dos_download_url=https://github.com/lumuzhi/config/blob/main/unix2dos.exe
singbox_download_url=https://github.com/SagerNet/sing-box/releases/download/v1.10.1/sing-box-1.10.1-linux-amd64.zip
update_downloadl_url=https://raw.githubusercontent.com/lumuzhi/config/main/mysb.sh
config_name="config"
country
local_version
remote_version

get_config_info() {
    while IFS='=' read -r key value; do
        case $key in
            version)
                local_version=$value
                ;;
            country)
                country=$value
                ;;
        esac
    done < "$config_name"
}


if [ ! -f "$config_name" ]; then
    curl -s "$version_download_url" | xargs -I {} echo "version={}" > config
    curl -s http://ipinfo.io/country | xargs -I {} echo "country={}" >> config
fi
get_config_info



tunmode() {
    if [ ! -f sfw/SFW ]; then
    fi
}

localmode() {
    if [! -f 'sb/sing-box' ]; then
        if [ "$country" == "CN" ]; then
            curl -sL -o sb.zip "${proxy}${singbox_download_url}"
        else
            curl -sL -o sb.zip "$singbox_download_url"
        fi
        
        if [ $? -eq 0 ]; then
            tar -xf sb.zip
            chmod +x sb/sing-box
        else
            echo "singbox下载失败"
            exit
        fi
    fi
    url="https://sbox.linwnrong.com"
    config_path="sb/config.json"

    curl -sL "$url" > "$config_path"
    if [ ! $? -eq 0 ]; then
        echo "获取配置文件失败"
    fi

    clear
    sb/sing-box run -c sb/config.json
}

lnmysb() {
    rm -rf /usr/bin/mysb
    curl -L -o /usr/bin/mysb -# --retry 2 --insecure "$1"
    chmod +x /usr/bin/mysb
}

update() {
    # if ! command -v unix2dos &> /dev/null; then
    #     apt update && apt install -y unix2dos
    # fi
    if [ "$country" == "CN" ]; then
        lnmysb "${proxy}${update_download_url}"
        # curl -sL "${proxy}${version_download_url}" | awk -F "更新内容" '{print $1}' | head -n 1 > v
    else
        lnmysb "$update_download_url"
        # curl -sL "$version_download_url" | awk -F "更新内容" '{print $1}' | head -n 1 > v
    fi
    
    green "sing-box脚本升级成功" && sleep 3 && mysb
}


main() {
    clear
    red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    white "tips:"
    blue "1. 全局代理：tun模式"
    bule "2. 本地代理：支持http，socks"
    white "----------------------------------------------------------------------------------"
    green "1. 全局代理"
    green "2. 本地代理"
    green "3. 更新脚本"
    green "0. 退出脚本"
    white "----------------------------------------------------------------------------------"
    red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    readp "选择：" Input
    case "$Input" in
        1) tunmode ;;
        2) localmode ;;
        3) update ;;
        0) exit ;;
        *) red "无效输入"
    esac
}


    

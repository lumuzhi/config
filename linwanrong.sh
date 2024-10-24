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
country=$(curl -s ipinfo.io/json)
# country="US"




setshortcut() {
  if [ "$country" = "CN" ]; then
    url="https://gh.kejilion.pro/https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  else
    url="https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  fi

  rm -rf /usr/bin/linwanrong
  curl -L -o /usr/bin/linwanrong --retry 2 --insecure $url
  chmod +x /usr/bin/linwanrong
  exit
}

update() {
  if [ "$country" = "CN" ]; then
    url="https://gh.kejilion.pro/https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  else
    url="https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  fi

  rm -rf /usr/bin/linwanrong
  curl -L -o /usr/bin/linwanrong -# --retry 2 --insecure $url
  chmod +x /usr/bin/linwanrong
  exit
}

# 参数 singbox on/off
singbox() {
  clear
  white "----------------------------------"
  green " 1. 开放端口"
  green " 2. 关闭端口"
  white "----------------------------------"
  green " 0. 返回上一层"
  white "----------------------------------"

  readp "输入数字：" Input
  case "$Input" in
    1 )
      iptables -I INPUT 1 -p tcp --dport 44500:44501 -j ACCEPT
      iptables -I INPUT 1 -p udp --dport 44502:44540 -j ACCEPT
      ;;
    2 )
      iptables -D INPUT -p tcp --dport 44500:44501 -j ACCEPT
      iptables -D INPUT -p udp --dport 44502:44540 -j ACCEPT
      ;;
    0 ) 
      sleep 2 && linwanrong
      ;;
    * )
      red "无效输入"
  esac
}


defaultIptables() {
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -p tcp --dport 22 -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -A INPUT -i lo -j ACCEPT
	iptables -P INPUT DROP
	iptables -P OUTPUT ACCEPT
	iptables -P FORWARD DROP
	netfilter-persistent save
	red "开启默认端口信息"
	iptables -L
}
main() {
  clear
  red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  white "脚本快捷方式：linwanrong"
  white "----------------------------------------------------------------------------------"
  green " 01. singbox"
  green " 02. 配置默认iptables"

  white "----------------------------------------------------------------------------------"
  green " 00. update"
  green " 0. exit"
  red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  readp "输入数字：" Input
  case "$Input" in
    01 ) singbox ;;
    02 ) defaultIptables ;;
    00 ) update ;;
    0 ) exit ;;
    * ) red "无效输入"
  esac
}


if [ "$#" -eq 0 ]; then
  # 如果没有参数，运行交互式
  main
fi

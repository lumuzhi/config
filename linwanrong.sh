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
# country=$(curl -s ipinfo.io/json)




setshortcut() {
  if [ "$country" = "CN" ]; then
    url="https://gh.kejilion.pro/https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  else
    url="https://raw.githubusercontent.com/lumuzhi/config/main/linwanrong.sh"
  fi

  rm -rf /usr/bin/linwanrong
  curl -L -o /usr/bin/linwanrong --retry 2 --insecure $url
  chmod +x /usr/bin/linwanrong
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
singboxport() {
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
      sleep 1 && linwanrong
      ;;
    * )
      red "无效输入"
  esac
}


defaultIptables() {
	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -F
	iptables -X
	iptables -t nat -F
	iptables -t nat -X
	iptables -t mangle -F
	iptables -t mangle -X
	iptables -t raw -F
	iptables -t raw -X
 	iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	iptables -P INPUT DROP
	iptables -P OUTPUT ACCEPT
	iptables -P FORWARD DROP
	iptables -A INPUT -p tcp --dport 22 -j ACCEPT
	iptables -A INPUT -p tcp --dport 443 -j ACCEPT
	iptables -A INPUT -p tcp --dport 80 -j ACCEPT
	iptables -A INPUT -p icmp -j ACCEPT
	iptables -A INPUT -i lo -j ACCEPT
 	apt install netfilter-persistent
	netfilter-persistent save
	red "已开启默认端口信息"
	iptables -L
}
installsingbox() {
  setshortcut
  clear
  bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh)
  exit
}
installdocker() {
  curl -fsSL https://get.docker.com | sh
  exit
}
# 安装 sbjson 服务
installsbjson() {
    local file_path=/opt/sbjson/main.py  # 指定文件路径作为函数参数
    if [ ! -f "$file_path" ]; then
      mkdir -p /opt/sbjson
      touch "$file_path"
    fi
    cat << 'EOF' > "$file_path"
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

# 定义一个请求处理类
class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # 检查请求路径是否是根路径 "/"
        if self.path == "/":
            # 设置响应头
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()

            # 读取文件内容
            try:
                with open(r'/etc/s-box/sing_box_client.json', 'r', encoding='utf-8') as f:
                    data = json.load(f)  # 读取 JSON 数据
                # 将 JSON 数据作为响应体返回
                self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))
            except Exception as e:
                # 如果文件读取失败，则返回 500 错误
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error reading file: {str(e)}".encode('utf-8'))
        else:
            # 处理未知路径，返回 404 错误
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b"404 Not Found")

# 设置服务器地址和端口
server_address = ('', 44601)

# 创建 HTTP 服务器
httpd = HTTPServer(server_address, SimpleHTTPRequestHandler)

# print("Server started on port 3000...")
httpd.serve_forever()
EOF

    # 给文件赋予可执行权限（可选）
    chmod +x "$file_path"
    if [ ! -f /etc/systemd/system/sbjson.service ]; then
      touch /etc/systemd/system/sbjson.service
    fi
    cat << 'EOF' > /etc/systemd/system/sbjson.service
[Unit]
Description=Python Script Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/sbjson/main.py
WorkingDirectory=/opt/sbjson
Restart=always
RestartSec=5
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    systemd enable sbjson.service
    systemd start sbjson.service

}
# 指定端口
port() {
    case $1 in
      # 增加某个端口 port tcp/udp 端口号
      add)
        shift
        iptables -I INPUT 1 -p $1 --dport $2 -j ACCEPT
        iptables -L
        ;;
      # 删除某个端口 port tcp/udp 端口号
      del)
        shift
        iptables -D INPUT -p $1 --dport $2 -j ACCEPT
        iptables -L
        ;;
       *) red "无效参数"
    esac
}
main() {
  clear
  red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
  white "脚本快捷方式：linwanrong"
  white "----------------------------------------------------------------------------------"
  green " 1. 安装 singbox"
  green " 2. singbox 端口"
  green " 3. 安装 sbjson 服务dddd"
  white "----------------------------------------------------------------------------------"
  green " 4. 安装 docker"
  white "----------------------------------------------------------------------------------"
  green " 5. 配置默认 iptables"
  white "----------------------------------------------------------------------------------"
  green " 9. update"
  green " 0. exit"
  red "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

  readp "输入数字：" Input
  case "$Input" in
    1 ) installsingbox ;;
    2 ) singboxport ;;
    3 ) installsbjson ;;
    4 ) installdocker ;;
    5 ) defaultIptables ;;
    9 ) update ;;
    0 ) exit ;;
    * ) red "无效输入"
  esac
}


if [ "$#" -eq 0 ]; then
  # 如果没有参数，运行交互式
  main
else
  case $1 in
    port)
      shift
      port "$@"
      ;;
    *) exit
  esac
fi

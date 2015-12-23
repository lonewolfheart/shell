#!/bin/bash
############################################
#           云服务器带宽检查脚本         
#
#version:1.0
#使用方法：
#例：./vmnetcheck.sh [eth0|eth1]
#参数说明：
#不写参数时，默认检查外网网卡eth1
# eth0  :检查内网网卡 
# eth1  :检查外网网卡
#其他：
#脚本需要按q键退出，无法使用ctrl+c停止       
############################################

##使用方法
usage()
{
	echo -e "usage:\n$0 [eth0|eth1]"
	exit
}
##显示带宽
show_net()
{
	recv1=$(cat /sys/class/net/${vm_interface}/statistics/rx_bytes)
	send1=$(cat /sys/class/net/${vm_interface}/statistics/tx_bytes)
	sleep 1
	recv2=$(cat /sys/class/net/${vm_interface}/statistics/rx_bytes)
	send2=$(cat /sys/class/net/${vm_interface}/statistics/tx_bytes)
	recv_Bps=$(($recv2-$recv1))
	send_Bps=$(($send2-$send1))
	recv_KBps=$(echo "${recv_Bps} 1024" |awk '{printf("%0.2f\n",$1/$2)}')
	send_KBps=$(echo "${send_Bps} 1024" |awk '{printf("%0.2f\n",$1/$2)}')
	recv_Mbps=$(echo "${recv_KBps} 1024 8" |awk '{printf("%0.2f\n",$1/$2*$3)}')
	send_Mbps=$(echo "${send_KBps} 1024 8" |awk '{printf("%0.2f\n",$1/$2*$3)}')
	echo -e "\033[5;1H网卡:${vm_interface}\t入带宽: ${recv_KBps} KB/s (${recv_Mbps} Mb/s) \t出带宽: ${send_KBps} KB/s (${send_Mbps} Mb/s)"
}
##检查ssh服务状态
check_sshd()
{
	sshd_port_tmp=$(grep -i ^port /etc/ssh/sshd_config|awk '{print $2}')
	sshd_port=${sshd_port_tmp:-22}
	sshd_root_state_tmp=$(grep ^PermitRootLogin /etc/ssh/sshd_config|tail -1|awk '{print $2}'|tr [A-Z] [a-z])
	sshd_root_state=${sshd_root_state_tmp:-yes}
	sshd_passwd_state_tmp=$(grep ^PasswordAuthentication /etc/ssh/sshd_config|tail -1|awk '{print $2}'|tr [A-Z] [a-z])
	sshd_passwd_state=${sshd_passwd_state_tmp:-yes}
	echo -e "\033[2;1Hssh端口为:"${sshd_port}
	echo -e "\033[2;60Hssh允许root登陆:${sshd_root_state}"
	echo -e "\033[2;120Hssh允许密码验证:${sshd_passwd_state}"
}
##检查IP
check_ip()
{
	internal_ip=$(ifconfig |grep -A 1 eth0|grep inet|awk -F: '{print $2}'|awk '{print $1}')
	internat_ip=$(ifconfig |grep -A 1 eth1|grep inet|awk -F: '{print $2}'|awk '{print $1}')
	if [ -n "${internal_ip}" ];then
		echo -ne "\033[1;1H内网IP:"${internal_ip}
	else
		echo -ne "\033[1;1H内网IP:none"
	fi
	if [ -n "${internat_ip}" ];then
                echo -ne "\033[1;60H外网IP:"${internat_ip}
        else
                echo -ne "\033[1;60H外网IP:none"
        fi
	is_icmp=$(cat /proc/sys/net/ipv4/icmp_echo_ignore_all)
	if [ "${is_icmp}x" == "1"x ];then
	echo -ne "\033[1;120Hicmp:已禁ping"
	fi
}
##netstat状态
curr_conn_net()
{
	curr_conn_tcp=$(netstat -anp|grep ^tcp|grep -v :::|grep ESTABLISHED |sort -rn -k 3|awk '{print $1,"\t入队列:",$2,"\t出队列:",$3,"\t  本地IP:",$4,"\t\t远程IP:",$5,"\tPID/进程:",$NF}')
	if [ -n "${curr_conn_tcp}" ];then
		echo -e "\r\033[K${curr_conn_tcp}\n\n"|grep -v 132|head -15
	fi
	curr_conn_udp=$(netstat -anp|grep ^udp|grep -v ::|grep ESTABLISHED |sort -rn -k 3|awk '{print $1,"\t入队列:",$2,"\t出队列:",$3,"\t  本地IP:",$4,"\t\t远程IP:",$5,"\tPID/进程:",$NF}')
	if [ -n "$curr_conn_udp" ];then
		echo -ne "\r\033[K${curr_conn_udp}"|grep -v 132|head -15
	fi
}

##脚本参数检查
if [ $# -gt 1 ];then
	usage
elif [ $# -eq 0 ];then
	:
else
	if [ "$1"x != "eth0"x ] && [ "$1"x != "eth1"x ];then
	usage
	fi
fi
##设定检测网卡
vm_interface=${1:-eth1}
##网卡文件检查
if [ ! -e /sys/class/net/${vm_interface} ];then
	echo "网卡:${vm_interface}不存在，请核实!"
	usage
	exit
fi
clear
##按q退出
stty intr q
echo -ne "\033[4;1H按\033[31mq\033[0m键退出"
##开始执行
check_sshd
check_ip

##循环显示
while true
do
##隐藏提示符
#echo -ne "\033[?25l"
show_net ${vm_interface}
curr_conn_net
#echo -e "\033[?25h"
done

#!/bin/bash

apt -y install wget unzip

# install besttrace
if [ ! -f "besttrace" ]; then
  wget https://cdn.ipip.net/17mon/besttrace4linux.zip
  unzip besttrace4linux.zip
  chmod +x besttrace
fi

## start to use besttrace

ip_list=(14.215.116.1 101.95.120.109 117.28.254.129 113.207.32.65 119.6.6.6 183.192.160.3 183.221.253.100 202.112.14.151)
ip_addr=(广州电信 上海电信 厦门电信 重庆联通 四川联通 上海移动 成都移动 成都教育网)
# ip_len=${#ip_list[@]}

for i in {0..7}
do
	echo ${ip_addr[$i]}
	./besttrace -q 1 ${ip_list[$i]}
done

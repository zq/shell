#!/bin/bash

# apt -y install unzip

# install besttrace
if [ ! -f "besttrace2021" ]; then
    wget https://github.com/zq/shell/raw/master/besttrace2021
    # unzip besttrace4linux.zip
    chmod +x besttrace2021
fi

## start to use besttrace

next() {
    printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear
next

ip_list=(219.141.136.12 202.106.50.1 221.179.155.161 202.96.209.133 210.22.97.1 211.136.112.200 58.60.188.222 210.21.196.6 120.196.165.24 202.112.14.151)
ip_addr=(北京电信 北京联通 北京移动 上海电信 上海联通 上海移动 深圳电信 深圳联通 深圳移动 成都教育网)
# ip_len=${#ip_list[@]}

for i in {0..7}
do
	echo ${ip_addr[$i]}
	./besttrace2021 -q 1 ${ip_list[$i]}
	next
done

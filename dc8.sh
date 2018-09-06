#!/bin/bash

#####  请先删除下面一行再运行脚本  #####

echo && echo -e "\033[41;36m 请务必仔细阅读相关注释后再运行此脚本，本人不对此脚本运行后所产生的后果负责！ \033[0m" && echo && exit 0 # 删除本行后运行

#####  请先删除上面一行再运行脚本  #####

#####  更多信息：https://www.bandwagonhost.net/2341.html

B=USCA_8

#####  请先填写下面信息再运行脚本  #####

VEID=        ## 请到搬瓦工后台 API 里找到 VEID 并在此填写，注意直接写在等号后面，不要空格
API_KEY=     ## 请到搬瓦工后台 API 里找到 API_KEY 并在此填写，注意直接写在等号后面，不要空格

#####  请先填写上面信息再运行脚本  #####

info() {
    A=(`wget -qO- "https://api.64clouds.com/v1/migrate/getLocations?&veid=${VEID}&api_key=${API_KEY}" | cut -d":" -f3 | cut -d"," -f1 | sed 's/\"//g'`)
}

info
while [[ $A != $B ]]
do
    wget -qO- "https://api.64clouds.com/v1/migrate/start?location=${B}&veid=${VEID}&api_key=${API_KEY}"
    sleep 10s
    info
done

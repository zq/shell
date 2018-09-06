#!/bin/bash
echo && echo -e "\033[41;36m 请务必仔细阅读相关注释后再运行此脚本，本人不对此脚本运行后所产生的后果负责！ \033[0m" && echo && exit 0 # 删除本行后运行
B=USCA_8
bwh_id=      #请到bwh后台 API 里找到 ID 并在此填写
bwh_key=     #请到bwh后台 API 里找到 KEY 并在此填写

info() {
    A=(`wget -qO- "https://api.64clouds.com/v1/migrate/getLocations?&veid=${bwh_id}&api_key=${bwh_key}" | cut -d":" -f3 | cut -d"," -f1 | sed 's/\"//g'`)
}

info
while [[ $A != $B ]]
do
    wget -qO- "https://api.64clouds.com/v1/migrate/start?location=${B}&veid=${bwh_id}&api_key=${bwh_key}"
    sleep 10s
    info
done

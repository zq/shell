#!/bin/bash

# =========================================================
# 搬瓦工中文网 - VPS 线路智能甄别系统 (v4.9 移动修正版)
# 更新日志：
# 1. 修正移动 CMIN2 识别逻辑：AS58453 -> AS58807
# 2. 将 AS58453 归类为标准 CMI 线路 (AS58453 != CMIN2)
# =========================================================

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
SKYBLUE='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'
PURPLE='\033[0;35m'

# 初始化汇总分类数组
ROWS_CT=()
ROWS_CU=()
ROWS_CM=()
ROWS_EDU=()
ROWS_OTHER=()

# 0. 权限检查
if [[ $EUID -ne 0 ]]; then
    clear
    echo -e "${RED}#############################################################${PLAIN}"
    echo -e "${RED}#                                                           #${PLAIN}"
    echo -e "${RED}#  错误：本脚本需要 Root 权限才能正常运行！                 #${PLAIN}"
    echo -e "${RED}#                                                           #${PLAIN}"
    echo -e "${RED}#############################################################${PLAIN}"
    echo ""
    echo -e "请尝试执行以下命令切换到 Root 用户："
    echo -e "${GREEN}sudo -i${PLAIN}"
    exit 1
fi

# 1. 环境检查与安装
if [ ! -f "/usr/local/bin/nexttrace" ]; then
    echo -e "${YELLOW}正在安装 NextTrace...${PLAIN}"
    curl nxtrace.org/nt | bash
fi

# 2. 分隔符
next() {
    echo -e "${SKYBLUE}----------------------------------------------------------------------${PLAIN}"
}

# 3. 核心分析逻辑 (修正移动 ASN 判定)
analyze_route() {
    local log_content=$1
    local isp_type=$2
    local target_name=$3
    local target_ip=$4
    
    local clean_content=$(echo "$log_content" | sed 's/\x1b\[[0-9;]*m//g')
    
    # --- 特征提取 (严谨版) ---
    # CN2
    local has_as4809=$(echo "$clean_content" | grep -E "AS4809|59\.43\.")
    
    # 联通
    local has_as9929=$(echo "$clean_content" | grep -E "AS9929|99\.29\.|AS10099")
    local has_as4837=$(echo "$clean_content" | grep -E "AS4837|219\.158\.")
    
    # 移动 (关键修正)
    # CMIN2 必须是 AS58807
    local has_cmin2=$(echo "$clean_content" | grep -E "AS58807") 
    # CMI 通常是 AS58453 或 AS9808(境外)
    local has_cmi=$(echo "$clean_content" | grep -E "AS58453|AS9808|223\.120\.")
    
    # 国内段特征
    local domestic_segment=$(echo "$clean_content" | grep -iE "China|CN|Beijing|Shanghai|Guangzhou|Shenzhen|Chengdu|Anhui|Sichuan|Guangdong")
    local domestic_has_4809=$(echo "$domestic_segment" | grep -E "AS4809|59\.43\.")

    local ret_color_type=""

    echo -e "${YELLOW}>>> [智能分析] 线路判定 (目标: $isp_type)：${PLAIN}"

    # --- 判定优先级瀑布 ---

    # 1. CN2 GIA (AS4809 国内段) - 最高优先级
    if [ -n "$domestic_has_4809" ]; then
        echo -e "   类型：${GREEN}${BOLD}电信 CN2 GIA (AS4809)${PLAIN}"
        echo -e "   详情：检测到回程国内段走 AS4809，顶级线路。"
        ret_color_type="${GREEN}CN2 GIA${PLAIN}"
        
    # 2. 联通 9929
    elif [ -n "$has_as9929" ]; then
        echo -e "   类型：${GREEN}${BOLD}联通 9929 (CU Premium)${PLAIN}"
        echo -e "   详情：检测到 AS9929 (联通A网) 骨干。"
        ret_color_type="${GREEN}联通 9929${PLAIN}"

    # 3. 移动 CMIN2 (AS58807) - 修正点
    elif [ -n "$has_cmin2" ]; then
        echo -e "   类型：${GREEN}${BOLD}移动 CMIN2 (AS58807)${PLAIN}"
        echo -e "   详情：检测到移动高端精品网 AS58807。"
        ret_color_type="${GREEN}移动 CMIN2${PLAIN}"

    # 4. CN2 GT (AS4809 仅国际段)
    elif [ -n "$has_as4809" ]; then
        echo -e "   类型：${YELLOW}${BOLD}电信 CN2 GT (Global Transit)${PLAIN}"
        echo -e "   详情：仅国际段走 AS4809，回国切入 163 骨干。"
        ret_color_type="${YELLOW}CN2 GT${PLAIN}"

    # 5. 联通 4837
    elif [ -n "$has_as4837" ]; then
        echo -e "   类型：${SKYBLUE}联通 4837 (169 Backbone)${PLAIN}"
        echo -e "   详情：联通民用骨干网。"
        ret_color_type="${SKYBLUE}联通 4837${PLAIN}"

    # 6. 移动 CMI (AS58453/AS9808) - 修正点
    elif [ -n "$has_cmi" ]; then
        echo -e "   类型：${SKYBLUE}移动 CMI (AS58453/9808)${PLAIN}"
        echo -e "   详情：走移动国际线路 (CMI)。"
        ret_color_type="${SKYBLUE}移动 CMI${PLAIN}"

    # 7. 兜底判定
    else
        case $isp_type in
            "CT")
                echo -e "   类型：${RED}电信 163 骨干网 (AS4134)${PLAIN}"
                ret_color_type="${RED}163 骨干${PLAIN}"
                ;;
            "CU")
                echo -e "   类型：${RED}联通普通线路${PLAIN}"
                ret_color_type="联通普通"
                ;;
            "CM")
                echo -e "   类型：${PURPLE}移动普通线路${PLAIN}"
                ret_color_type="${PURPLE}移动普通${PLAIN}"
                ;;
            "EDU")
                echo -e "   类型：${SKYBLUE}教育网 (CERNET)${PLAIN}"
                ret_color_type="${SKYBLUE}教育网${PLAIN}"
                ;;
            *)
                echo -e "   类型：其他/混合网络"
                ret_color_type="其他网络"
                ;;
        esac
    fi

    # === 构建汇总行 ===
    local name_len=${#target_name}
    local pad_spaces=""
    if [[ $name_len -eq 4 ]]; then pad_spaces="        "; fi
    if [[ $name_len -eq 5 ]]; then pad_spaces="      "; fi
    if [[ $name_len -eq 3 ]]; then pad_spaces="          "; fi
    if [[ $name_len -eq 6 ]]; then pad_spaces="    "; fi
    if [[ -z "$pad_spaces" ]]; then pad_spaces="    "; fi

    local summary_line=$(printf "%s%s %-18s %-20b" "$target_name" "$pad_spaces" "$target_ip" "$ret_color_type")

    if [[ "$isp_type" == "CT" ]]; then ROWS_CT+=("$summary_line"); fi
    if [[ "$isp_type" == "CU" ]]; then ROWS_CU+=("$summary_line"); fi
    if [[ "$isp_type" == "CM" ]]; then ROWS_CM+=("$summary_line"); fi
    if [[ "$isp_type" == "EDU" ]]; then ROWS_EDU+=("$summary_line"); fi
    if [[ "$isp_type" == "OTHER" ]]; then ROWS_OTHER+=("$summary_line"); fi
}

detect_isp_type() {
    local log_content=$1
    local lower_content=$(echo "$log_content" | tr '[:upper:]' '[:lower:]')
    if echo "$lower_content" | grep -qE "telecom|dx|as4134|as4809"; then echo "CT"
    elif echo "$lower_content" | grep -qE "unicom|lt|as4837|as9929"; then echo "CU"
    elif echo "$lower_content" | grep -qE "mobile|yd|as9808|cmi"; then echo "CM"
    elif echo "$lower_content" | grep -qE "education|cernet|edu"; then echo "EDU"
    else echo "OTHER"; fi
}

# 辅助函数：打印最终汇总表
print_final_summary() {
    echo ""
    echo -e "${GREEN}#############################################################${PLAIN}"
    echo -e "${GREEN}#            搬瓦工中文网 - VPS 回程路由测评汇总            #${PLAIN}"
    echo -e "${GREEN}#   (https://www.bandwagonhost.net | https://www.bwg.net)   #${PLAIN}"
    echo -e "${GREEN}#          使用方法：wget -qO- besttrace.sh | bash          #${PLAIN}"
    echo -e "${GREEN}#############################################################${PLAIN}"
    
    echo -e "节点名称         IP 地址            线路类型"
    echo "-------------------------------------------------------------"
    
    for line in "${ROWS_CT[@]}"; do echo -e "$line"; done
    for line in "${ROWS_CU[@]}"; do echo -e "$line"; done
    for line in "${ROWS_CM[@]}"; do echo -e "$line"; done
    for line in "${ROWS_EDU[@]}"; do echo -e "$line"; done
    for line in "${ROWS_OTHER[@]}"; do echo -e "$line"; done

    echo "-------------------------------------------------------------"
    echo -e "${YELLOW}* 图例: ${GREEN}绿色=高端(GIA/9929/CMIN2)${PLAIN} | ${SKYBLUE}蓝色=主流(4837/CMI)${PLAIN} | ${RED}红色=普通${PLAIN}"
    echo -e "${YELLOW}* 提示: 线路类型判断结果仅供参考，具体以实际路由和表现为准${PLAIN}"
    echo ""
}

# 4. 定义数据源
ip_list=("219.141.147.210" "202.106.50.1" "221.179.155.161" \
         "202.96.209.133" "210.22.97.1" "211.136.112.200" \
         "202.96.128.86"   "210.21.196.6" "120.196.165.24" \
         "118.112.11.12" "119.6.6.6" "211.137.96.205" \
         "202.112.14.151")

ip_addr=("北京电信" "北京联通" "北京移动" \
         "上海电信" "上海联通" "上海移动" \
         "广州电信" "广州联通" "广州移动" \
         "成都电信" "成都联通" "成都移动" \
         "成都教育网")

isp_codes=("CT" "CU" "CM" "CT" "CU" "CM" "CT" "CU" "CM" "CT" "CU" "CM" "EDU")

# 5. 交互菜单逻辑
clear
echo -e "${GREEN}#############################################################${PLAIN}"
echo -e "${GREEN}#            搬瓦工中文网 - VPS 回程路由测评汇总            #${PLAIN}"
echo -e "${GREEN}#   (https://www.bandwagonhost.net | https://www.bwg.net)   #${PLAIN}"
echo -e "${GREEN}#          使用方法：wget -qO- besttrace.sh | bash          #${PLAIN}"
echo -e "${GREEN}#############################################################${PLAIN}"

echo -e "请选择测试模式："
echo -e "${GREEN}0.${PLAIN} 测试所有节点 (默认 - 直接回车)"
echo -e "${SKYBLUE}1.${PLAIN} 仅测试 电信 (China Telecom)"
echo -e "${SKYBLUE}2.${PLAIN} 仅测试 联通 (China Unicom)"
echo -e "${SKYBLUE}3.${PLAIN} 仅测试 移动 (China Mobile)"
echo -e "${SKYBLUE}4.${PLAIN} 仅测试 教育网 (Education)"
echo -e "${YELLOW}5.${PLAIN} 自定义 IP 测试 (自动识别运营商)"
echo ""
read -p "请输入选项 [0-5]: " choice < /dev/tty

if [[ -z "$choice" ]]; then choice="0"; fi

case $choice in
    0) mode_name="测试所有节点" ;;
    1) mode_name="仅测试 电信 (China Telecom)" ;;
    2) mode_name="仅测试 联通 (China Unicom)" ;;
    3) mode_name="仅测试 移动 (China Mobile)" ;;
    4) mode_name="仅测试 教育网 (Education)" ;;
    5) mode_name="自定义 IP 测试" ;;
    *) mode_name="未知模式" ;;
esac

if [[ "$choice" == "5" ]]; then
    echo ""
    read -p "请输入目标 IP: " custom_ip < /dev/tty
    echo -e "\n正在测试: ${GREEN}自定义测速点${PLAIN} [${custom_ip}]"
    nexttrace "$custom_ip" -q 1 -M | tee /tmp/nt_temp.log
    raw_log=$(cat /tmp/nt_temp.log)
    detected_isp=$(detect_isp_type "$raw_log")
    analyze_route "$raw_log" "$detected_isp" "自定义测速点" "$custom_ip"
    rm -f /tmp/nt_temp.log
    print_final_summary
    exit 0
fi

clear
echo -e "${GREEN}=== 开始测试 (模式: $mode_name) ===${PLAIN}"
next

len=${#ip_list[@]}
count=0

for ((i=0; i<len; i++)); do
    target_ip=${ip_list[$i]}
    target_name=${ip_addr[$i]}
    isp_type=${isp_codes[$i]}
    
    should_run=false
    case $choice in
        0) should_run=true ;;
        1) if [[ "$isp_type" == "CT" ]]; then should_run=true; fi ;;
        2) if [[ "$isp_type" == "CU" ]]; then should_run=true; fi ;;
        3) if [[ "$isp_type" == "CM" ]]; then should_run=true; fi ;;
        4) if [[ "$isp_type" == "EDU" ]]; then should_run=true; fi ;;
    esac
    
    if $should_run; then
        ((count++))
        echo -e "正在测试: ${GREEN}${target_name}${PLAIN} [${target_ip}]"
        nexttrace "$target_ip" -q 1 -M | tee /tmp/nt_temp.log
        analyze_route "$(cat /tmp/nt_temp.log)" "$isp_type" "$target_name" "$target_ip"
        next
        sleep 1
    fi
done

rm -f /tmp/nt_temp.log
if [[ $count -eq 0 ]]; then
    echo -e "${YELLOW}提示：该模式下没有匹配的测试节点。${PLAIN}"
else
    print_final_summary
fi

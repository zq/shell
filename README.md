# shell

## 回程路由测试

【2025-12】上线全新 BestTrace.sh

核心亮点：

 - 方便的一键运行：无需复杂的依赖安装，只需一行命令即可进行测试。
 - 深度融合 NextTrace：底层采用了更为先进、可视化的 NextTrace 路由追踪引擎，使用了 LeoMoeAPI 等高精度 IP 库，能够准确显示每一跳的物理位置和运营商信息
 - 智能线路分析：不同于传统的只显示 IP 跳数，该脚本内置了智能分析功能。它能自动识别并标注关键线路类型（如 CN2 GIA、移动 CMIN2、联通 9929 等），让小白用户也能一眼看懂线路质量。
 - 更全的测试节点：本次优化并新增了部分测试节点，网络类型包括电信、联通、移动、教育网，测试地点包含北京、上海、广州、成都等。
 - 直观的测评汇总：在所有节点测试完成后，脚本会汇总一个测试结果，免去繁杂的手动分析环节。

使用方法：

    wget -qO- besttrace.sh | bash

官网地址：https://besttrace.sh

详情介绍：https://www.bandwagonhost.net/16156.html

旧版依旧可以使用：

    wget -qO- git.io/besttrace | bash
    
详情介绍：https://www.bandwagonhost.net/2345.html
    
## 一键迁入 DC8（已废弃，不建议使用）

详情介绍：https://www.bandwagonhost.net/2341.html

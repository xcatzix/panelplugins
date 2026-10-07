1. 去掉Modules中keyboard layout及相关的设置选项; 去掉Modules中Media模块及相关的设置选项.
2. 合并Clock和System & FPS模块,让其同时显示.合并后排列顺序从左到右为Clock 和System.
   比对Clock和System模块,将Clock中重复的功能去掉.
3. 增加点击Clock,打开/usr/bin/korganizer; 点击System, 打开/usr/bin/xfce4-taskmanager
4. 将netspeedmonitor集成到org.kde.plasma.dynamicIzland上,显示在notify上,即当notify接收到消息时,
   显示消息,没有接收到消息,则显示网络速度. dynamicIzland的长度为可调的定值, 不能乱伸展.
5. notification log: ${HOME}/.cache/dynamicIzland/notify.log
6. 检查一下代码,进行必要的优化.
# MiuiVariableThermal_magisk
这是一个运行在安卓设备上的magisk模块。

[下载页面](https://github.com/410154425/MiuiVariableThermal_magisk/releases)点击Assets选择压缩包MiuiVariableThermal_magisk_***.zip，使用Magisk从本地安装。

利用MIUI云温控，使充电场景、游戏场景在温控层面用不同档位的快充和性能无限制，其它场景自动恢复系统默认温控，可配置MIUI旁路供电、锁定屏幕刷新率，配置路径：/data/adb/modules/MiuiVariableThermal/config.conf，日志log.log。

模块仅对MIUI云温控/data/vendor/thermal/config/文件进行动态修改，不会对系统默认温控文件/vendor/etc/thermal-***.conf做任何修改。
本模块无法解决游戏内锁帧问题(一般是因为joyose云控)，你需要找'去除云控锁帧'的方法解决。

-目前充电档位有5个，到配置文件按照自己能接受的温度选择充电快慢。

-本模块与其它控制电流的模块/软件冲突(关键词：电流)，可与'去云控模块'共存，与其它温控模块/系统内核若冲突面具会提示。


# MiuiVariableThermal_magisk
这是一个运行在安卓设备上的magisk模块。

[下载页面](https://github.com/410154425/MiuiVariableThermal_magisk/releases)点击Assets选择压缩包MiuiVariableThermal_magisk_***.zip，使用Magisk从本地安装。

利用MIUI云温控，使不同场景使用不同的温控或关闭温控，比如充电或游戏场景实现快充和性能不受温控的限制，其它场景自动恢复默认温控，配置路径：/data/adb/modules/MiuiVariableThermal/config.conf，日志log.log。

模块仅对MIUI云温控/data/vendor/thermal/config/文件进行动态修改，不会对系统默认温控文件/vendor/etc/thermal-***.conf做任何修改。
本模块无法解决游戏内锁帧问题(云控原因)，你需要找'去云控'的类型模块解决。

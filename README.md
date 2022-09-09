# AdGuardHome_magisk
这是一个让AdGuardHome运行在安卓设备上的去广告magisk模块。

[下载页面](https://github.com/410154425/MiuiVariableThermal_magisk/releases)点击Assets选择压缩包MiuiVariableThermal_magisk_***.zip，使用Magisk从本地安装。

利用MIUI云控/data/vendor/thermal/config/进行动态修改，使不同场景使用不同的温控文件，比如充电或游戏场景使用空白文件实现充电和性能不受温控文件的限制，其它场景自动恢复默认温控文件，配置路径：/data/adb/modules/MiuiVariableThermal/config.conf。

# AdGuardHome_magisk
这是一个让AdGuardHome运行在安卓设备上的去广告magisk模块。

[下载页面](https://github.com/410154425/MiuiVariableThermal_magisk/releases)点击Assets选择压缩包MiuiVariableThermal_magisk_***.zip，使用Magisk从本地安装。

利用MIUI云控，使得不同场景使用不同的温控策略或是关闭温控，比如充电或游戏场景关闭温控实现快充和性能的不限制，其它场景自动恢复默认温控，配置路径：/data/adb/modules/MiuiVariableThermal/config.conf。

充电场景：当充电时，则使用/data/adb/modules/MiuiVariableThermal/thermal/thermal-charge.conf文件覆盖所有MIUI云控，使得系统使用该文件作为温控，该文件默认为空文件，你也可以自定义一个温控文件到该路径下，命名为thermal-charge.conf使之在充电场景生效。

充电场景容易高温，若不加以限制，是难以持续的，这里给两个建议方案：1.在/vendor/etc/复制一个温控文件出来，用Scene5软件的MIUI温控功能修改成你喜欢的参数保存，把修改后的文件命名(不同名称代表不同场景，请详读上下文了解)放到本模块目录/data/adb/modules/MiuiVariableThermal/thermal/里使之生效。2.使用QSC定量停充模块，可根据温度限制充电电流，需内核提供节点支持才有效，请自行测试。

游戏场景：设备当前显示app若在[游戏场景app列表]内，则使用/data/adb/modules/MiuiVariableThermal/thermal/thermal-app.conf文件覆盖所有MIUI云控，使得系统使用该文件作为温控，该文件默认为空文件，你也可以自定义一个温控文件到该路径下，命名为thermal-app.conf使之在游戏场景生效。
thermal_app=1

游戏场景app列表：
一个app格式：app_list=包名
多个app格式：app_list=包名|包名|包名
要严格按格式填写，否则无法识别触发，只需填一行。
app_list=com.tencent.tmgp.pubgmhd|com.tencent.tmgp.sgame|com.miHoYo.Yuanshen

优先级说明：若同时触发充电场景和游戏场景，则使用游戏场景的温控。

其它情况下使用系统默认的温控，即/vendor/etc/目录里的温控文件，你也可以自定义一个温控文件到/data/adb/modules/MiuiVariableThermal/thermal/路径下，命名为thermal-default.conf使之在默认场景生效，删除该文件则恢复一般情况下使用系统默认的温控策略。

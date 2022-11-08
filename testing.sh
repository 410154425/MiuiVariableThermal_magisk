#!/system/bin/sh
#
#如发现模块BUG，执行此脚本文件，把结果截图给作者，谢谢！
#
MODDIR=${0%/*}
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
state="$(cat "$MODDIR/module.prop" | egrep '^description=' | sed -n 's/.*=\[//g;s/\].*//g;p')"
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;$p')"
module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
global_switch="$(echo "$config_conf" | egrep '^global_switch=' | sed -n 's/global_switch=//g;$p')"
echo --------- 版本 ----------
echo "$module_version ,$module_versionCode"
echo --------- 适配 ----------
dumpsys activity | egrep 'mResume'
dumpsys window | egrep 'mCurrentFocus'
echo "$state"
thermal_program="mi_thermald thermal-engine thermal-engine-v2 thermalserviced"
for i in $thermal_program ; do
	which_thermal="$(which "$i")"
	if [ -f "$which_thermal" ]; then
		cat_thermal="$(cat "$which_thermal" | wc -c)"
		pgrep_thermal="$(pgrep "$i" | sed -n '1p')"
		thermal_data="$which_thermal,$cat_thermal,$pgrep_thermal,$thermal_data"
	fi
done
echo "$thermal_data"
decrypt_dump="$(ls -A /data/vendor/thermal)"
for i in $decrypt_dump ; do
	if [ -f "/data/vendor/thermal/$i" ]; then
		decrypt_dump_c="$(cat "/data/vendor/thermal/$i" | wc -c)"
		decrypt_dump_config="$i $decrypt_dump_c,$decrypt_dump_config"
	fi
done
if [ -f "$MODDIR/thermal_list" ]; then
	thermal_list="$(cat "$MODDIR/thermal_list" | wc -l)"
	t_list="thermal_list,$thermal_list"
else
	t_list="no,thermal_list"
fi
ls_z_config="$(ls -Z /data/vendor/thermal | egrep 'config')"
echo "$decrypt_dump_config,$ls_z_config,$t_list"
dumpsys_charging="$(dumpsys deviceidle get charging)"
bypass_supply_mode=0
if [ -f "$MODDIR/on_bypass" ]; then
	bypass_supply_mode=1
fi
mode="$(cat "$MODDIR/mode")"
fps="$(echo "$config_conf" | egrep '^fps=')"
current_max="$(echo "$config_conf" | egrep '^current_max=' | sed -n 's/current_max=//g;$p')"
thermal_scene="$(echo "$config_conf" | egrep '^thermal_scene=' | sed -n 's/thermal_scene=//g;$p')"
thermal_scene_time="$(echo "$config_conf" | egrep '^thermal_scene_time=' | sed -n 's/thermal_scene_time=//g;$p')"
thermal_charge="$(echo "$config_conf" | egrep '^thermal_charge=' | sed -n 's/thermal_charge=//g;$p')"
thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
current_now="$(cat '/sys/class/power_supply/battery/current_now')"
battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
if [ -f "$MODDIR/stop_level" ]; then
	stop_level="$(cat "$MODDIR/stop_level")"
fi
bypass_supply_level="$(echo "$config_conf" | egrep '^bypass_supply_level=' | sed -n 's/bypass_supply_level=//g;$p')"
battery_temp="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
bypass_supply_temp="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p')"
bypass_supply_app="$(echo "$config_conf" | egrep '^bypass_supply_app=' | sed -n 's/bypass_supply_app=//g;$p')"
echo "模式$mode 充电档位$thermal_scene 时间档位$thermal_scene_time 充电场景$thermal_charge 游戏场景$thermal_app 刷新率$fps 充电状态$dumpsys_charging 电流模式$current_max 电流$current_now 旁停$stop_level 手动旁路$bypass_supply_mode 电量$battery_level 电量旁路$bypass_supply_level 温度$battery_temp 温度旁路$bypass_supply_temp 游戏旁路$bypass_supply_app 版本$module_version"
echo --------- 电流节点 ----------
battery_current_list="/sys/class/power_supply/battery/constant_charge_current_max /sys/class/power_supply/battery/constant_charge_current /sys/class/power_supply/battery/fast_charge_current /sys/class/power_supply/battery/thermal_input_current /sys/class/power_supply/battery/current_max"
for i in $battery_current_list ; do
	if [ -f "$i" ]; then
		battery_current_data="$(cat "$i")"
		battery_current_node="$i,$battery_current_data,$battery_current_node"
	fi
done
echo "$battery_current_node"
echo --------- 系统温控 ----------
thermal_normal="$(find /system/*/* -type f -iname "*thermal*.conf" -o -type f -iname "*mi_thermald*" -o -type f -iname "*thermal-engine*" -o -type f -iname "*thermalserviced*")"
for i in $thermal_normal ; do
	thermal_normal_c="$(cat "$i" | wc -c)"
	thermal_etc="$i $thermal_normal_c,$thermal_etc"
done
echo "$thermal_etc"
echo --------- MIUI云温控 ----------
thermal_normal="$(ls -A /data/vendor/thermal/config)"
for i in $thermal_normal ; do
	if [ -f "/data/vendor/thermal/config/$i" ]; then
		thermal_normal_c="$(cat "/data/vendor/thermal/config/$i" | wc -c)"
		thermal_config="$i $thermal_normal_c,$thermal_config"
	fi
done
echo "$thermal_config"
echo --------- 设备信息 ----------
echo "release.$(getprop ro.build.version.release | sed -n 's/ //g;$p'),sdk.$(getprop ro.build.version.sdk | sed -n 's/ //g;$p'),brand.$(getprop ro.product.brand | sed -n 's/ //g;$p'),model.$(getprop ro.product.model | sed -n 's/ //g;$p'),cpu.$(cat '/proc/cpuinfo' | egrep 'Hardware' | sed -n 's/.*://g;s/ //g;$p')"
if [ -f "$MODDIR/disable" -o "$global_switch" = "0" ]; then
	echo --------- 模块已关闭 ----------
	exit 0
fi
if [ "$thermal_app" = "1" ]; then
	app_list="$(echo "$config_conf" | egrep '^app_list=' | sed -n 's/app_list=//g;$p')"
	activity_window="$(dumpsys activity | egrep 'mResume' | egrep "$app_list")"
	if [ -n "$app_list" -a -n "$activity_window" ]; then
		echo --------- 游戏场景 ----------
		thermal_app_c="$(cat "$MODDIR/thermal/thermal-app.conf" | wc -c)"
		echo "thermal-app.conf $thermal_app_c"
		exit 0
	fi
fi
if [ "$thermal_charge" = "1" ]; then
	dumpsys_charging="$(dumpsys deviceidle get charging)"
	if [ "$dumpsys_charging" = "true" ]; then
		echo --------- 充电场景 ----------
		thermal_charge_c="$(cat "$MODDIR/thermal/thermal-charge.conf" | wc -c)"
		echo "thermal-charge.conf $thermal_charge_c"
		exit 0
	else
		echo --------- 默认场景 ----------
		if [ -f "$MODDIR/thermal/thermal-default.conf" ]; then
			thermal_default_c="$(cat "$MODDIR/thermal/thermal-default.conf" | wc -c)"
			echo "thermal-default.conf $thermal_default_c"
		else
			echo "no thermal-default.conf"
		fi
		exit 0
	fi
else
	echo --------- 默认场景 ----------
	if [ -f "$MODDIR/thermal/thermal-default.conf" ]; then
		thermal_default_c="$(cat "$MODDIR/thermal/thermal-default.conf" | wc -c)"
		echo "thermal-default.conf $thermal_default_c"
	else
		echo "no thermal-default.conf"
	fi
	exit 0
fi

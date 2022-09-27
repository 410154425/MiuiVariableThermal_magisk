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
fps="$(echo "$config_conf" | egrep '^fps=')"
echo --------- 版本 ----------
echo "$module_version ,$module_versionCode"
echo --------- 适配 ----------
dumpsys activity | egrep 'mResume'
dumpsys window | egrep 'mCurrentFocus'
echo "$state"
getprop vendor.sys.thermal.data.path
which_thermal="$(which -a 'mi_thermald')"
cat_thermal="$(cat "$which_thermal" | wc -c)"
pgrep_thermal="$(pgrep 'mi_thermald')"
echo "$which_thermal $cat_thermal $pgrep_thermal"
getprop sys.thermal.data.path
which_thermal="$(which -a 'thermal-engine')"
cat_thermal="$(cat "$which_thermal" | wc -c)"
pgrep_thermal="$(pgrep 'thermal-engine')"
echo "$which_thermal $cat_thermal $pgrep_thermal"
if [ -f "/data/vendor/thermal/decrypt.txt" ]; then
	decrypt_txt="$(cat "/data/vendor/thermal/decrypt.txt" | wc -c)"
	echo "yes decrypt.txt $decrypt_txt"
else
	echo "no decrypt.txt"
fi
if [ -f "/data/vendor/thermal/thermal.dump" ]; then
	thermal_dump="$(cat "/data/vendor/thermal/thermal.dump" | wc -c)"
	echo "yes thermal.dump $thermal_dump"
else
	echo "no thermal.dump"
fi
if [ -f "$MODDIR/thermal_list" ]; then
	thermal_list="$(cat "$MODDIR/thermal_list" | wc -l)"
	echo "yes thermal_list $thermal_list"
else
	echo "no thermal_list"
fi
echo "$fps"
dumpsys_charging="$(dumpsys deviceidle get charging)"
bypass_supply_mode=0
if [ -f "$MODDIR/on_bypass" ]; then
	bypass_supply_mode=1
fi
mode="$(cat "$MODDIR/mode")"
thermal_scene="$(echo "$config_conf" | egrep '^thermal_scene=' | sed -n 's/thermal_scene=//g;$p')"
thermal_charge="$(echo "$config_conf" | egrep '^thermal_charge=' | sed -n 's/thermal_charge=//g;$p')"
thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
current_now="$(cat '/sys/class/power_supply/battery/current_now')"
battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
bypass_supply_level="$(echo "$config_conf" | egrep '^bypass_supply_level=' | sed -n 's/bypass_supply_level=//g;$p')"
battery_temp="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
bypass_supply_temp="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p')"
bypass_supply_app="$(echo "$config_conf" | egrep '^bypass_supply_app=' | sed -n 's/bypass_supply_app=//g;$p')"
echo "当前模式$mode 温控档位$thermal_scene 充电场景$thermal_charge 游戏场景$thermal_app 充电$dumpsys_charging 电流$current_now 手动旁路$bypass_supply_mode 电量$battery_level 电量旁路$bypass_supply_level 温度$battery_temp 温度旁路$bypass_supply_temp 游戏旁路$bypass_supply_app"
echo --------- 系统温控 ----------
find /system/*/* -name "*thermal*.conf" -o -name "*mi_thermald*" -o -name "*thermal-engine*" > "$MODDIR/testing_list"
thermal_normal="$(cat "$MODDIR/testing_list")"
thermal_normal_n="$(echo "$thermal_normal" | wc -l)"
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "$thermal_normal_p" | wc -c)"
	thermal_etc="$thermal_normal_p $thermal_normal_c , $thermal_etc"
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
done
echo "$thermal_etc"
echo --------- MIUI云温控 ----------
thermal_normal="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
thermal_normal_n="$(echo "$thermal_normal" | egrep 'thermal\-' | wc -l)"
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "/data/vendor/thermal/config/$thermal_normal_p" | wc -c)"
	thermal_config="$thermal_normal_p $thermal_normal_c , $thermal_config"
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
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

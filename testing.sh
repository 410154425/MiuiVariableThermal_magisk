#!/system/bin/sh
#
#如发现模块BUG，执行此脚本文件，把结果截图给作者，谢谢！
#
MODDIR=${0%/*}
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
state="$(cat "$MODDIR/module.prop" | egrep '^description=' | sed -n 's/.*=\[//g;s/\].*//g;p')"
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;$p')"
module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
thermal_charge="$(echo "$config_conf" | egrep '^thermal_charge=' | sed -n 's/thermal_charge=//g;$p')"
thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
global_switch="$(echo "$config_conf" | egrep '^global_switch=' | sed -n 's/global_switch=//g;$p')"
echo --------- 版本 ----------
echo "$module_version ,$module_versionCode"
echo --------- 状态 ----------
echo "$state"
getprop vendor.sys.thermal.data.path
pgrep 'mi_thermald'
getprop sys.thermal.data.path
pgrep 'thermal-engine'
if [ -f "/data/vendor/thermal/decrypt.txt" ]; then
	decrypt_l="$(cat "/data/vendor/thermal/decrypt.txt" | wc -l)"
	echo "yes decrypt.txt $decrypt_l"
else
	echo "no decrypt.txt"
fi
echo --------- 系统温控 ----------
thermal_normal="$(cat "$MODDIR/thermal_list")"
thermal_normal_n="$(echo "$thermal_normal" | wc -l)"
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "/system/vendor/etc/$thermal_normal_p" | wc -c)"
	thermal_etc="$thermal_normal_p $thermal_normal_c , $thermal_etc"
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
done
echo "$thermal_etc"
echo --------- MIUI云控 ----------
thermal_normal="$(cat "$MODDIR/thermal_list")"
thermal_normal_n="$(echo "$thermal_normal" | wc -l)"
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "/data/vendor/thermal/config/$thermal_normal_p" | wc -c)"
	thermal_config="$thermal_normal_p $thermal_normal_c , $thermal_config"
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
done
echo "$thermal_config"
echo --------- 设备信息 ----------
echo "serialno.$(getprop ro.serialno | sed -n 's/ //g;$p'),release.$(getprop ro.build.version.release | sed -n 's/ //g;$p'),sdk.$(getprop ro.build.version.sdk | sed -n 's/ //g;$p'),brand.$(getprop ro.product.brand | sed -n 's/ //g;$p'),model.$(getprop ro.product.model | sed -n 's/ //g;$p')"
if [ -f "$MODDIR/disable" -o "$global_switch" = "0" ]; then
	echo --------- 模块已关闭 ----------
	exit 0
fi
if [ "$thermal_app" = "1" ]; then
	app_list="$(echo "$config_conf" | egrep '^app_list=' | sed -n 's/app_list=//g;$p')"
	activity_mResume="$(dumpsys activity | egrep 'mResume' | egrep "$app_list")"
	if [ -n "$app_list" -a -n "$activity_mResume" ]; then
		echo --------- 触发游戏场景 ----------
		thermal_app_c="$(cat "$MODDIR/thermal/thermal-app.conf" | wc -c)"
		echo "thermal-app.conf $thermal_app_c"
		exit 0
	fi
fi
if [ "$thermal_charge" = "1" ]; then
	dumpsys_charging="$(dumpsys deviceidle get charging)"
	if [ "$dumpsys_charging" = "true" ]; then
		echo --------- 触发充电场景 ----------
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

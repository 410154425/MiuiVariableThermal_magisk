MODDIR=${0%/*}
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
mode="$(cat "$MODDIR/mode")"
thermal_unlimited="$(echo "$config_conf" | egrep '^thermal_unlimited=' | sed -n 's/thermal_unlimited=//g;$p')"
log_log=0
data_vendor_thermal="$(getprop vendor.sys.thermal.data.path)"
thermal_program='mi_thermald'
if [ ! -n "$data_vendor_thermal" ]; then
	data_vendor_thermal="$(getprop sys.thermal.data.path)"
	thermal_program='thermal-engine'
fi
if [ ! -n "$data_vendor_thermal" ]; then
	sed -i 's/\[.*\]/\[ 系统不支持MIUI云温控或被屏蔽删除，请使用支持MIUI云温控的设备及系统 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
	exit 0
fi
if [ ! -d "/data/vendor/thermal/config" ]; then
	mkdir -p "/data/vendor/thermal/config" >/dev/null 2>&1
fi
chmod 0771 "/data/vendor/thermal" >/dev/null 2>&1
chmod 0771 "/data/vendor/thermal/config" >/dev/null 2>&1
chmod 0660 "/data/vendor/thermal/decrypt.txt" >/dev/null 2>&1
t_blank_md5="$(md5sum "$MODDIR/t_blank" | cut -d ' ' -f '1' )"
md5_blank="eea43bc6fb93d22d052ddc74ade02830"
if [ "$t_blank_md5" != "$md5_blank" ]; then
	sed -i 's/\[.*\]/\[ 模块缺少文件t_blank，请重新安装重启 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
	exit 0
fi
log_n="$(cat "$MODDIR/log.log" | wc -l)"
if [ "$log_n" -gt "20" ]; then
	sed -i '1,5d' "$MODDIR/log.log" > /dev/null 2>&1
fi
start_thermal_program() {
	stop mi_thermald >/dev/null 2>&1
	stop thermal-engine >/dev/null 2>&1
	start mi_thermald >/dev/null 2>&1
	start thermal-engine >/dev/null 2>&1
	if [ -f "$MODDIR/thermal_stop" ]; then
		rm -f "$MODDIR/thermal_stop" > /dev/null 2>&1
	fi
	thermal_program_id="$(pgrep "$thermal_program")"
	if [ ! -n "$thermal_program_id" ]; then
		sed -i "s/\[.*\]/\[ 系统温控程序$thermal_program被屏蔽删除，请恢复重启后再使用 \]/g" "$MODDIR/module.prop" >/dev/null 2>&1
		exit 0
	fi
}
stop_thermal_program() {
	stop mi_thermald >/dev/null 2>&1
	stop thermal-engine >/dev/null 2>&1
	start mi_thermald >/dev/null 2>&1
	start thermal-engine >/dev/null 2>&1
	stop mi_thermald >/dev/null 2>&1
	stop thermal-engine >/dev/null 2>&1
	touch "$MODDIR/thermal_stop" > /dev/null 2>&1
}
t_blank_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1' )"
		if [ "$thermal_config_md5" != "$md5_blank" ]; then
			cp "$MODDIR/t_blank" "/data/vendor/thermal/config/$thermal_p" >/dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	if [ "$thermal_unlimited" = "1" ]; then
		if [ "$log_log" = "1" -o "$mode" != "5" ]; then
			stop_thermal_program
			echo "5" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：极限模式 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：极限模式" >> "$MODDIR/log.log"
		fi
	else
		if [ "$log_log" = "1" -o "$mode" != "4" ]; then
			start_thermal_program
			echo "4" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：空白文件 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：空白文件" >> "$MODDIR/log.log"
		fi
	fi
}
thermal_app_conf() {
	thermal_app_md5="$(md5sum "$MODDIR/thermal/thermal-app.conf" | cut -d ' ' -f '1' )"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1' )"
		if [ "$thermal_config_md5" != "$thermal_app_md5" ]; then
			cp "$MODDIR/thermal/thermal-app.conf" "/data/vendor/thermal/config/$thermal_p" >/dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	if [ "$log_log" = "1" -o "$mode" != "3" ]; then
		start_thermal_program
		echo "3" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-app.conf \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-app.conf" >> "$MODDIR/log.log"
	fi
}
thermal_charge_conf() {
	thermal_charge_md5="$(md5sum "$MODDIR/thermal/thermal-charge.conf" | cut -d ' ' -f '1' )"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1' )"
		if [ "$thermal_config_md5" != "$thermal_charge_md5" ]; then
			cp "$MODDIR/thermal/thermal-charge.conf" "/data/vendor/thermal/config/$thermal_p" >/dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	if [ "$log_log" = "1" -o "$mode" != "2" ]; then
		start_thermal_program
		echo "2" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-charge.conf \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-charge.conf" >> "$MODDIR/log.log"
	fi
}
thermal_default_conf() {
	thermal_default_md5="$(md5sum "$MODDIR/thermal/thermal-default.conf" | cut -d ' ' -f '1' )"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1' )"
		if [ "$thermal_config_md5" != "$thermal_default_md5" ]; then
			cp "$MODDIR/thermal/thermal-default.conf" "/data/vendor/thermal/config/$thermal_p" >/dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	if [ "$log_log" = "1" -o "$mode" != "1" ]; then
		start_thermal_program
		echo "1" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-default.conf \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-default.conf" >> "$MODDIR/log.log"
	fi
}
thermal_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$thermal_p" | cut -d ' ' -f '1' )"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1' )"
		if [ "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$thermal_p" "/data/vendor/thermal/config/$thermal_p" >/dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	if [ "$log_log" = "1" -o "$mode" != "0" ]; then
		start_thermal_program
		echo "0" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：系统默认 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：系统默认" >> "$MODDIR/log.log"
	fi
}
delete_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		rm -f "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
		thermal_n="$(( $thermal_n - 1 ))"
	done
}
global_switch="$(echo "$config_conf" | egrep '^global_switch=' | sed -n 's/global_switch=//g;$p')"
if [ -f "$MODDIR/disable" -o "$global_switch" = "0" ]; then
	if [ ! -f "$MODDIR/stop" ]; then
		thermal_conf
		delete_conf
		sed -i 's/\[.*\]/\[ 模块已关闭 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		echo "$(date +%F_%T) 模块已关闭" >> "$MODDIR/log.log"
		touch "$MODDIR/stop" > /dev/null 2>&1
	fi
	exit 0
else
	if [ -f "$MODDIR/stop" ]; then
		rm -f "$MODDIR/stop" > /dev/null 2>&1
	fi
fi
thermal_program_id="$(pgrep 'mi_thermald|thermal-engine')"
if [ -f "$MODDIR/thermal_stop" -a -n "$thermal_program_id" ]; then
	stop_thermal_program
fi
thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
if [ "$thermal_app" = "1" ]; then
	app_list="$(echo "$config_conf" | egrep '^app_list=' | sed -n 's/app_list=//g;$p')"
	activity_window="$(dumpsys window | egrep 'mCurrentFocus' | egrep "$app_list")"
	if [ -n "$app_list" -a -n "$activity_window" ]; then
		thermal_app_c="$(cat "$MODDIR/thermal/thermal-app.conf" | wc -c)"
		if [ "$thermal_app_c" -lt "20" ]; then
			t_blank_conf
			exit 0
		else
			thermal_app_conf
			exit 0
		fi
	fi
fi
thermal_charge="$(echo "$config_conf" | egrep '^thermal_charge=' | sed -n 's/thermal_charge=//g;$p')"
if [ "$thermal_charge" = "1" ]; then
	dumpsys_charging="$(dumpsys deviceidle get charging)"
	if [ "$dumpsys_charging" = "true" ]; then
		thermal_charge_c="$(cat "$MODDIR/thermal/thermal-charge.conf" | wc -c)"
		if [ "$thermal_charge_c" -lt "20" ]; then
			t_blank_conf
			exit 0
		else
			thermal_charge_conf
			exit 0
		fi
	fi
fi
if [ -f "$MODDIR/thermal/thermal-default.conf" ]; then
	thermal_default_c="$(cat "$MODDIR/thermal/thermal-default.conf" | wc -c)"
	if [ "$thermal_default_c" -lt "20" ]; then
		t_blank_conf
		exit 0
	else
		thermal_default_conf
		exit 0
	fi
fi
thermal_conf
exit 0
#version=2022091200
# ##

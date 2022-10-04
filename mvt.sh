MODDIR=${0%/*}
log_c=0
log_log=0
bypass_supply_mode=0
log_n="$(cat "$MODDIR/log.log" | wc -l)"
if [ "$log_n" -gt "30" ]; then
	sed -i '1,5d' "$MODDIR/log.log" > /dev/null 2>&1
fi
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
default_max="22000000"
if [ ! -f "$MODDIR/thermal_list" ]; then
	find /system/vendor/etc -type f -iname "thermal*.conf" | sed -n 's/\/system\/vendor\/etc\///g;p' | egrep -v '\/' > "$MODDIR/thermal_list"
	rm -f "$MODDIR/mode" > /dev/null 2>&1
	sed -i 's/\[.*\]/\[ 文件thermal_list丢失，正在创建，稍等 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
	exit 0
fi
chattr -R -i -a '/data/vendor/thermal/'
if [ ! -d '/data/vendor/thermal/config/' ]; then
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
fi
chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
t_blank_md5="$(md5sum "$MODDIR/t_blank" | cut -d ' ' -f '1')"
md5_blank="7787e0abdb1f98d5c7fd713fa70a1884"
if [ "$t_blank_md5" != "$md5_blank" ]; then
	rm -f "$MODDIR/mode" > /dev/null 2>&1
	sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则模块t_blank文件错误，请重新安装模块重启 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
	thermal_t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
	if [ "$thermal_t_blank_md5" = "$md5_blank" ]; then
		cp "$MODDIR/thermal/t_blank" "$MODDIR/t_blank" > /dev/null 2>&1
	fi
	exit 0
fi
t_bypass_md5="$(md5sum "$MODDIR/t_bypass" | cut -d ' ' -f '1')"
md5_bypass="9385b51aecde23f39aec307bdd362b58"
if [ "$t_bypass_md5" != "$md5_bypass" ]; then
	rm -f "$MODDIR/mode" > /dev/null 2>&1
	sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则模块t_bypass文件错误，请重新安装模块重启 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
	thermal_t_bypass_md5="$(md5sum "$MODDIR/thermal/t_bypass" | cut -d ' ' -f '1')"
	if [ "$thermal_t_bypass_md5" = "$md5_bypass" ]; then
		cp "$MODDIR/thermal/t_bypass" "$MODDIR/t_bypass" > /dev/null 2>&1
	fi
	exit 0
fi
start_thermal_program() {
	thermal_program="mi_thermald thermal-engine thermal-engine-v2 thermalserviced"
	for i in $thermal_program ; do
		which_thermal="$(which "$i")"
		if [ -f "$which_thermal" ]; then
			stop "$i" > /dev/null 2>&1
		fi
	done
	chattr -R -i -a '/data/vendor/thermal/'
	rm -f '/data/vendor/thermal/thermal.dump' > /dev/null 2>&1
	for i in $thermal_program ; do
		which_thermal="$(which "$i")"
		if [ -f "$which_thermal" ]; then
			start "$i" > /dev/null 2>&1
		fi
	done
	thermal_program_id="$(pgrep 'mi_thermald|thermal-engine|thermal-engine-v2|thermalserviced')"
	if [ -n "$thermal_program_id" ]; then
		if [ ! -f '/data/vendor/thermal/thermal.dump' ]; then
			sleep 1
			dump_n=5
			until [ -f '/data/vendor/thermal/thermal.dump' -o "$dump_n" = "0" ] ; do
				sleep 1
				dump_n="$(( $dump_n - 1 ))"
			done
			if [ ! -f '/data/vendor/thermal/thermal.dump' ]; then
				while true ; do
					rm -f "$MODDIR/mode" > /dev/null 2>&1
					rm -f "$MODDIR/max_c" > /dev/null 2>&1
					sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则可能系统不支持MIUI云温控，也可能被第三方屏蔽或删除了，请排查温控相关的模块冲突，重启再试 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					chattr -R -i -a '/data/vendor/thermal/'
					rm -rf '/data/vendor/thermal/' > /dev/null 2>&1
					sleep 1
				done
			fi
		fi
	else
		rm -f "$MODDIR/mode" > /dev/null 2>&1
		rm -f "$MODDIR/max_c" > /dev/null 2>&1
		sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则系统温控程序被屏蔽或删除了，请恢复重启后再使用 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		exit 0
	fi
	if [ "$log_c" = "0" ]; then
		mi_thermald_id="$(pgrep 'mi_thermald')"
		if [ -n "$mi_thermald_id" ]; then
			for i in $thermal_program ; do
				if [ "$i" != 'mi_thermald' ]; then
					which_thermal="$(which "$i")"
					if [ -f "$which_thermal" ]; then
						stop "$i" > /dev/null 2>&1
					fi
				fi
			done
		fi
	fi
}
current_log() {
	current_txt="$(echo "$config_conf" | egrep '^current_txt=' | sed -n 's/current_txt=//g;$p')"
	if [ "$current_txt" = "1" ]; then
		current_n="$(cat "$MODDIR/current.txt" | wc -l)"
		if [ "$current_n" -gt "500" ]; then
			sed -i '1,50d' "$MODDIR/current.txt" > /dev/null 2>&1
		fi
		battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
		current_now="$(cat '/sys/class/power_supply/battery/current_now')"
		battery_temp="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
		if [ "$stop_level" -gt "0" ]; then
			echo "$(date +%F_%T) 电量$battery_level 电流上限$current_max 当前电流$current_now 温度$battery_temp 旁路$stop_level" >> "$MODDIR/current.txt"
		else
			echo "$(date +%F_%T) 电量$battery_level 电流上限$current_max 当前电流$current_now 温度$battery_temp" >> "$MODDIR/current.txt"
		fi
	fi
}
change_current() {
	if [ "$current_max" = "0" ]; then
		now_current="$(cat '/sys/class/power_supply/battery/current_now')"
		if [ -n "$now_current" ]; then
			echo "$now_current" >> "$MODDIR/now_current"
			now_current_n="$(cat "$MODDIR/now_current" | wc -l)"
			if [ "$now_current_n" -gt "15" ]; then
				sed -i '1,5d' "$MODDIR/now_current" > /dev/null 2>&1
			fi
			now_current_e="$(cat "$MODDIR/now_current" | egrep '\-' | wc -l)"
			if [ "$now_current_e" -ge "4" ]; then
				current_max="100000"
			else
				current_max="0"
			fi
		fi
	else
		if [ -f "$MODDIR/now_current" ]; then
			rm -f "$MODDIR/now_current" > /dev/null 2>&1
		fi
	fi
	current_log
	max_c="$(cat "$MODDIR/max_c")"
	if [ "$current_max" != "$max_c" ]; then
		battery_current_list="/sys/class/power_supply/battery/constant_charge_current_max /sys/class/power_supply/battery/constant_charge_current /sys/class/power_supply/battery/fast_charge_current /sys/class/power_supply/battery/thermal_input_current /sys/class/power_supply/battery/current_max"
		for i in $battery_current_list ; do
			if [ -f "$i" ]; then
				chmod 0644 "$i"
				echo "$current_max" > "$i"
				log_c=1
			fi
		done
		echo "$current_max" > "$MODDIR/max_c"
		if [ "$log_c" = "1" ]; then
			thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
			for i in $thermal_list ; do
				thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
				if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_bypass" ]; then
					cp "$MODDIR/t_bypass" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
				fi
			done
			thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
			for i in $thermal_list ; do
				thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
				thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
				if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
					cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
				fi
			done
			start_thermal_program
			mode="$(cat "$MODDIR/mode")"
			if [ "$bypass_supply_mode" = "1" ]; then
				if [ "$mode" != "6" ]; then
					echo "6" > "$MODDIR/mode"
					sed -i 's/\[.*\]/\[ 当前温控：温度-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					echo "$(date +%F_%T) 当前温控：温度-旁路供电" >> "$MODDIR/log.log"
				fi
				exit 0
			elif [ "$bypass_supply_mode" = "2" ]; then
				if [ "$mode" != "7" ]; then
					echo "7" > "$MODDIR/mode"
					sed -i 's/\[.*\]/\[ 当前温控：手动-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					echo "$(date +%F_%T) 当前温控：手动-旁路供电" >> "$MODDIR/log.log"
				fi
				exit 0
			elif [ "$bypass_supply_mode" = "3" ]; then
				if [ "$mode" != "8" ]; then
					echo "8" > "$MODDIR/mode"
					sed -i 's/\[.*\]/\[ 当前温控：电量-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					echo "$(date +%F_%T) 当前温控：电量-旁路供电" >> "$MODDIR/log.log"
				fi
				exit 0
			elif [ "$bypass_supply_mode" = "4" ]; then
				if [ "$mode" != "9" ]; then
					echo "9" > "$MODDIR/mode"
					sed -i 's/\[.*\]/\[ 当前温控：游戏-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					echo "$(date +%F_%T) 当前温控：游戏-旁路供电" >> "$MODDIR/log.log"
				fi
				exit 0
			fi
			rm -f "$MODDIR/mode" > /dev/null 2>&1
			sed -i 's/\[.*\]/\[ 温控切换中，请稍等10秒 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 温控切换中，请稍等10秒" >> "$MODDIR/log.log"
			sleep 10
			log_c=0
		fi
	fi
}
bypass_supply_current() {
	stop_level="$(cat "$MODDIR/stop_level")"
	battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
	if [ "$battery_level" -gt "0" ]; then
		until [ "$stop_level" -gt "0" ]; do
			stop_level="$battery_level"
			echo "$stop_level" > "$MODDIR/stop_level"
		done
		if [ "$battery_level" -gt "$stop_level" -o "$battery_level" = "100" ]; then
			current_max="0"
		else
			current_max="100000"
		fi
		change_current
	fi
}
stop_current() {
	if [ -f "$MODDIR/stop_level" ]; then
		current_max="$(echo "$config_conf" | egrep '^current_max=' | sed -n 's/current_max=//g;$p')"
		if [ -n "$current_max" -a "$current_max" -ge "1000000" ]; then
			change_current
		else
			current_max="$default_max"
			change_current
		fi
		rm -f "$MODDIR/stop_level" > /dev/null 2>&1
	fi
	if [ -f "$MODDIR/max_c" ]; then
		rm -f "$MODDIR/max_c" > /dev/null 2>&1
	fi
}
bypass_supply_md5() {
	bypass_supply_current
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_bypass" ]; then
			cp "$MODDIR/t_bypass" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
}
bypass_supply_conf() {
	battery_temp="$(cat '/sys/class/power_supply/battery/temp' | cut -c '1-2')"
	bypass_supply_temp_1="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p' | cut -d ' ' -f '1')"
	bypass_supply_temp_2="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p' | cut -d ' ' -f '2')"
	if [ -n "$battery_temp" -a -n "$bypass_supply_temp_2" -a "$bypass_supply_temp_1" -gt "$bypass_supply_temp_2" ]; then
		if [ "$battery_temp" -ge "$bypass_supply_temp_1" ]; then
			if [ ! -f "$MODDIR/on_bypass_temp" ]; then
				touch "$MODDIR/on_bypass_temp" > /dev/null 2>&1
			fi
		else
			if [ "$battery_temp" -le "$bypass_supply_temp_2" ]; then
				rm -f "$MODDIR/on_bypass_temp" > /dev/null 2>&1
			fi
		fi
	else
		rm -f "$MODDIR/on_bypass_temp" > /dev/null 2>&1
	fi
	if [ -f "$MODDIR/on_bypass_temp" ]; then
		bypass_supply_mode=1
	else
		if [ -f "$MODDIR/on_bypass" ]; then
			bypass_supply_mode=2
		else
			battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
			bypass_supply_level="$(echo "$config_conf" | egrep '^bypass_supply_level=' | sed -n 's/bypass_supply_level=//g;$p')"
			if [ "$bypass_supply_level" = "100" ]; then
				bypass_supply_level=99
			fi
			if [ -n "$battery_level" -a -n "$bypass_supply_level" -a "$battery_level" -ge "$bypass_supply_level" ]; then
				bypass_supply_mode=3
			else
				bypass_supply_app="$(echo "$config_conf" | egrep '^bypass_supply_app=' | sed -n 's/bypass_supply_app=//g;$p')"
				if [ "$app_on" = "1" -a "$bypass_supply_app" = "1" ]; then
					bypass_supply_mode=4
				fi
			fi
		fi
	fi
	if [ "$bypass_supply_mode" = "1" ]; then
		bypass_supply_md5
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "6" ]; then
			start_thermal_program
			echo "6" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：温度-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：温度-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "2" ]; then
		bypass_supply_md5
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "7" ]; then
			start_thermal_program
			echo "7" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：手动-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：手动-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "3" ]; then
		bypass_supply_md5
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "8" ]; then
			start_thermal_program
			echo "8" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：电量-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：电量-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "4" ]; then
		bypass_supply_md5
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "9" ]; then
			start_thermal_program
			echo "9" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：游戏-旁路供电 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：游戏-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	else
		current_max="$(echo "$config_conf" | egrep '^current_max=' | sed -n 's/current_max=//g;$p')"
		if [ -n "$current_max" -a "$current_max" -ge "1000000" ]; then
			change_current
		else
			current_max="$default_max"
			change_current
		fi
		if [ -f "$MODDIR/stop_level" ]; then
			rm -f "$MODDIR/stop_level" > /dev/null 2>&1
		fi
	fi
}
t_blank_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_blank" ]; then
			cp "$MODDIR/t_blank" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "5" ]; then
		start_thermal_program
		echo "5" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：零档-无限制 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：零档-无限制" >> "$MODDIR/log.log"
	fi
}
thermal_scene_conf() {
	thermal_scene_md5="$(md5sum "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | cut -d ' ' -f '1')"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_scene_md5" ]; then
			cp "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	if [ "$thermal_scene" = "1" ]; then
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "11" ]; then
			start_thermal_program
			echo "11" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：一档-无限制 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：一档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "2" ]; then
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "12" ]; then
			start_thermal_program
			echo "12" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：二档-无限制 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：二档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "3" ]; then
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "13" ]; then
			start_thermal_program
			echo "13" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：三档-无限制 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：三档-无限制" >> "$MODDIR/log.log"
		fi
	else
		mode="$(cat "$MODDIR/mode")"
		if [ "$log_log" = "1" -o "$mode" != "10" ]; then
			start_thermal_program
			echo "10" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：其它-无限制 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
			echo "$(date +%F_%T) 当前温控：其它-无限制" >> "$MODDIR/log.log"
		fi
	fi
}
thermal_app_conf() {
	thermal_app_md5="$(md5sum "$MODDIR/thermal/thermal-app.conf" | cut -d ' ' -f '1')"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_app_md5" ]; then
			cp "$MODDIR/thermal/thermal-app.conf" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "4" ]; then
		start_thermal_program
		echo "4" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-app.conf \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-app.conf" >> "$MODDIR/log.log"
	fi
}
thermal_charge_conf() {
	thermal_charge_md5="$(md5sum "$MODDIR/thermal/thermal-charge.conf" | cut -d ' ' -f '1')"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_charge_md5" ]; then
			cp "$MODDIR/thermal/thermal-charge.conf" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "3" ]; then
		start_thermal_program
		echo "3" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-charge.conf \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-charge.conf" >> "$MODDIR/log.log"
	fi
}
thermal_default_conf() {
	thermal_default_md5="$(md5sum "$MODDIR/thermal/thermal-default.conf" | cut -d ' ' -f '1')"
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i -v '\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_default_md5" ]; then
			cp "$MODDIR/thermal/thermal-default.conf" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map')"
	for i in $thermal_list ; do
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$i" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$i" "/data/vendor/thermal/config/$i" > /dev/null 2>&1
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "2" ]; then
		start_thermal_program
		echo "2" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-default.conf \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-default.conf" >> "$MODDIR/log.log"
	fi
}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf '/data/vendor/thermal/config/' > /dev/null 2>&1
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
	chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
}
thermal_conf() {
	thermal_config="$(ls -A /data/vendor/thermal/config)"
	if [ -n "$thermal_config" ]; then
		delete_conf
		log_log=1
	fi
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "1" ]; then
		start_thermal_program
		echo "1" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：系统默认 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：系统默认" >> "$MODDIR/log.log"
	fi
}
fps_lock() {
	fps="$(echo "$config_conf" | egrep '^fps=' | sed -n 's/fps=//g;$p' | cut -d ' ' -f '1')"
	if [ -n "$fps" -a "$fps" != "0" ]; then
		DisplayModeRecord="$(dumpsys display | egrep 'DisplayModeRecord')"
		DisplayModeRecord_id="$(echo "$DisplayModeRecord" | egrep "fps=$fps" | egrep -v '=\[\]' | sed -n 's/.*id=//g;s/,.*//g;1p')"
		if [ -n "$DisplayModeRecord_id" ]; then
			DisplayModeRecord_id="$(( $DisplayModeRecord_id - 1 ))"
			if [ "$DisplayModeRecord_id" != "-1" ]; then
				service call SurfaceFlinger 1035 i32 "$DisplayModeRecord_id" > /dev/null 2>&1
				if [ ! -f "$MODDIR/fps" ]; then
					touch "$MODDIR/fps" > /dev/null 2>&1
				fi
			fi
		fi
	fi
}
fps_recovery() {
	if [ -f "$MODDIR/fps" ]; then
		fps="$(echo "$config_conf" | egrep '^fps=' | sed -n 's/fps=//g;$p' | cut -d ' ' -f '2')"
		if [ -n "$fps" -a "$fps" != "0" ]; then
			DisplayModeRecord="$(dumpsys display | egrep 'DisplayModeRecord')"
			DisplayModeRecord_id="$(echo "$DisplayModeRecord" | egrep "fps=$fps" | egrep -v '=\[\]' | sed -n 's/.*id=//g;s/,.*//g;1p')"
			if [ -n "$DisplayModeRecord_id" ]; then
				DisplayModeRecord_id="$(( $DisplayModeRecord_id - 1 ))"
				if [ "$DisplayModeRecord_id" != "-1" ]; then
					service call SurfaceFlinger 1035 i32 "$DisplayModeRecord_id" > /dev/null 2>&1
				fi
			fi
		fi
		rm -f "$MODDIR/fps" > /dev/null 2>&1
	fi
}
global_switch="$(echo "$config_conf" | egrep '^global_switch=' | sed -n 's/global_switch=//g;$p')"
if [ -f "$MODDIR/disable" -o "$global_switch" = "0" ]; then
	mode="$(cat "$MODDIR/mode")"
	if [ "$mode" != 'stop' ]; then
		rm -f "$MODDIR/max_c" > /dev/null 2>&1
		rm -f "$MODDIR/stop_level" > /dev/null 2>&1
		rm -f "$MODDIR/now_current" > /dev/null 2>&1
		thermal_conf
		echo 'stop' > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 模块已关闭，重启生效 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 模块已关闭，重启生效" >> "$MODDIR/log.log"
	fi
	exit 0
fi
thermal_scene="$(echo "$config_conf" | egrep '^thermal_scene=' | sed -n 's/thermal_scene=//g;$p')"
screen_on="$(dumpsys deviceidle get screen)"
if [ "$screen_on" != 'false' ]; then
	thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
	if [ "$thermal_app" = "1" ]; then
		app_list="$(echo "$config_conf" | egrep '^app_list=' | sed -n 's/app_list=//g;$p')"
		if [ -n "$app_list" ]; then
			activity_window="$(dumpsys window | egrep 'mCurrentFocus' | egrep "$app_list")"
			if [ -f "$MODDIR/mCurrentFocus" ]; then
				if [ ! -n "$activity_window" ]; then
					activity_window="$(dumpsys activity | egrep 'mResume' | egrep "$app_list")"
				fi
			fi
			if [ -n "$activity_window" ]; then
				if [ ! -f "$MODDIR/mCurrentFocus" ]; then
					touch "$MODDIR/mCurrentFocus" > /dev/null 2>&1
				fi
				fps_lock
				dumpsys_charging="$(dumpsys deviceidle get charging)"
				if [ "$dumpsys_charging" = "true" ]; then
					app_on=1
					bypass_supply_conf
				else
					stop_current
				fi
				thermal_app_c="$(cat "$MODDIR/thermal/thermal-app.conf" | wc -c)"
				if [ "$thermal_app_c" -lt "100" ]; then
					if [ "$thermal_scene" -ge "1" ]; then
						thermal_scene_c="$(cat "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | wc -c)"
						if [ "$thermal_scene_c" -lt "100" ]; then
							t_blank_conf
						else
							thermal_scene_conf
						fi
					else
						t_blank_conf
					fi
				else
					thermal_app_conf
				fi
				exit 0
			else
				rm -f "$MODDIR/mCurrentFocus" > /dev/null 2>&1
			fi
		fi
	fi
fi
fps_recovery
dumpsys_charging="$(dumpsys deviceidle get charging)"
if [ "$dumpsys_charging" = "true" ]; then
	app_on=0
	bypass_supply_conf
	thermal_charge="$(echo "$config_conf" | egrep '^thermal_charge=' | sed -n 's/thermal_charge=//g;$p')"
	if [ "$thermal_charge" = "1" ]; then
		thermal_charge_c="$(cat "$MODDIR/thermal/thermal-charge.conf" | wc -c)"
		if [ "$thermal_charge_c" -lt "100" ]; then
			if [ "$thermal_scene" -ge "1" ]; then
				thermal_scene_c="$(cat "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | wc -c)"
				if [ "$thermal_scene_c" -lt "100" ]; then
					t_blank_conf
				else
					thermal_scene_conf
				fi
			else
				t_blank_conf
			fi
		else
			thermal_charge_conf
		fi
		exit 0
	fi
else
	stop_current
fi
if [ -f "$MODDIR/thermal/thermal-default.conf" ]; then
	thermal_default_c="$(cat "$MODDIR/thermal/thermal-default.conf" | wc -c)"
	if [ "$thermal_default_c" -lt "100" ]; then
		if [ "$thermal_scene" -ge "1" ]; then
			thermal_scene_c="$(cat "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | wc -c)"
			if [ "$thermal_scene_c" -lt "100" ]; then
				t_blank_conf
			else
				thermal_scene_conf
			fi
		else
			t_blank_conf
		fi
	else
		thermal_default_conf
	fi
	exit 0
fi
thermal_conf
exit 0
#version=2022100400
# ##

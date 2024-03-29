MODDIR=${0%/*}
log_log=0
bypass_supply_mode=0
log_n="$(cat "$MODDIR/log.log" | wc -l)"
if [ "$log_n" -gt "30" ]; then
	sed -i '1,5d' "$MODDIR/log.log"
fi
now_current="$(cat '/sys/class/power_supply/battery/current_now')"
battery_level="$(cat '/sys/class/power_supply/battery/capacity')"
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
current_max="$(echo "$config_conf" | egrep '^current_max=' | sed -n 's/current_max=//g;$p')"
if [ "$current_max" -ge "1000000" ]; then
	bypass_max=1
else
	bypass_max=0
	if [ -f "$MODDIR/max_c" ]; then
		rm -f "$MODDIR/max_c"
	fi
fi
if [ ! -f "$MODDIR/thermal_list" ]; then
	find /system/vendor/etc -type f -iname "thermal*.conf" | sed -n 's/\/system\/vendor\/etc\///g;p' | egrep -v '\/' > "$MODDIR/thermal_list"
	rm -f "$MODDIR/mode"
	sed -i 's/\[.*\]/\[ 文件thermal_list丢失，正在创建，稍等 \]/g' "$MODDIR/module.prop"
	exit 0
fi
chattr -R -i -a '/data/vendor/thermal'
if [ ! -d '/data/vendor/thermal/config' ]; then
	rm -f '/data/vendor/thermal/config'
	if [ ! -d '/data/vendor/thermal' ]; then
		chattr -i -a '/data/vendor'
		rm -f '/data/vendor/thermal'
	fi
	rm -f "$MODDIR/mode"
	mkdir -p '/data/vendor/thermal/config'
	chown -R root:system '/data/vendor/thermal'
	chcon -R 'u:object_r:thermal_data_file:s0' '/data/vendor/thermal'
fi
ls_z_config="$(ls -Z /data/vendor/thermal | egrep 'config' | egrep 'u:object_r:thermal_data_file:s0')"
if [ ! -n "$ls_z_config" ]; then
	rm -f "$MODDIR/mode"
	chown -R root:system '/data/vendor/thermal'
	chcon -R 'u:object_r:thermal_data_file:s0' '/data/vendor/thermal'
fi
chmod -R 0771 '/data/vendor/thermal'
t_blank_md5="$(md5sum "$MODDIR/t_blank" | cut -d ' ' -f '1')"
md5_blank="de59942d3dffc090f0dae74dfc4d47ce"
t_bypass_0_md5="$(md5sum "$MODDIR/t_bypass_0" | cut -d ' ' -f '1')"
md5_bypass_0="006bb13431c52592192e710e46e76879"
t_bypass_1_md5="$(md5sum "$MODDIR/t_bypass_1" | cut -d ' ' -f '1')"
md5_bypass_1="959b4f8711503653abea8a019936ab2c"
t_map_md5="$(md5sum "$MODDIR/t_map" | cut -d ' ' -f '1')"
md5_map="43b4b914ef6b45119bbfe2030e4025a7"
if [ "$t_blank_md5" != "$md5_blank" -o "$t_bypass_0_md5" != "$md5_bypass_0" -o "$t_bypass_1_md5" != "$md5_bypass_1" -o "$t_map_md5" != "$md5_map" ]; then
	rm -f "$MODDIR/mode"
	sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则模块文件错误，请重新安装模块重启 \]/g' "$MODDIR/module.prop"
	thermal_t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
	if [ -f "$MODDIR/thermal/t_blank" -a "$thermal_t_blank_md5" = "$md5_blank" ]; then
		cp "$MODDIR/thermal/t_blank" "$MODDIR/t_blank"
	fi
	thermal_t_bypass_0_md5="$(md5sum "$MODDIR/thermal/t_bypass_0" | cut -d ' ' -f '1')"
	if [ -f "$MODDIR/thermal/t_bypass_0" -a "$thermal_t_bypass_0_md5" = "$md5_bypass_0" ]; then
		cp "$MODDIR/thermal/t_bypass_0" "$MODDIR/t_bypass_0"
	fi
	thermal_t_bypass_1_md5="$(md5sum "$MODDIR/thermal/t_bypass_1" | cut -d ' ' -f '1')"
	if [ -f "$MODDIR/thermal/t_bypass_1" -a "$thermal_t_bypass_1_md5" = "$md5_bypass_1" ]; then
		cp "$MODDIR/thermal/t_bypass_1" "$MODDIR/t_bypass_1"
	fi
	thermal_t_map_md5="$(md5sum "$MODDIR/thermal/t_map" | cut -d ' ' -f '1')"
	if [ -f "$MODDIR/thermal/t_map" -a "$thermal_t_map_md5" = "$md5_map" ]; then
		cp "$MODDIR/thermal/t_map" "$MODDIR/t_map"
	fi
	exit 0
fi
md5_bypass="$md5_bypass_0"
t_bypass='t_bypass_0'
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal'
	rm -rf /data/vendor/thermal/config/*
}
program_data() {
	chattr -R -i -a '/data/vendor/thermal'
	stat_decrypt_2="$stat_decrypt_1"
	decrypt_n=3
	until [ "$stat_decrypt_1" != "$stat_decrypt_2" -o "$decrypt_n" = "0" ] ; do
		echo "$(date +%F_%T)" > '/data/vendor/thermal/config/mvt.conf'
		sleep 1
		decrypt_n="$(( $decrypt_n - 1 ))"
		stat_decrypt_2="$(stat -c %Y '/data/vendor/thermal/decrypt.txt')"
		if [ ! -n "$stat_decrypt_2" ]; then
			stat_decrypt_2="$stat_decrypt_1"
		fi
	done
}
pgrep_thermal_program() {
	which_thermal_1="$(which 'mi_thermald')"
	which_thermal_2="$(which 'thermal-engine')"
	if [ -f "$which_thermal_1" ]; then
		thermal_program='mi_thermald'
	elif [ -f "$which_thermal_2" ]; then
		thermal_program='thermal-engine'
	else
		rm -f "$MODDIR/mode"
		rm -f "$MODDIR/max_c"
		sed -i 's/\[.*\]/\[ 机型或系统不支持，无法使用 \]/g' "$MODDIR/module.prop"
		exit 0
	fi
	thermal_program_id="$(pgrep "$thermal_program")"
	if [ ! -n "$thermal_program_id" ]; then
		rm -f "$MODDIR/mode"
		rm -f "$MODDIR/max_c"
		sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则系统温控进程文件被屏蔽或删除了，请排查移除冲突后重启再试 \]/g' "$MODDIR/module.prop"
		exit 0
	fi
}
start_thermal_program() {
	program_data
	if [ "$stat_decrypt_1" = "$stat_decrypt_2" ]; then
		chown -R root:system '/data/vendor/thermal'
		chcon -R 'u:object_r:thermal_data_file:s0' '/data/vendor/thermal'
		stop "$thermal_program"
		start "$thermal_program"
		program_data
		if [ "$stat_decrypt_1" = "$stat_decrypt_2" ]; then
			while true ; do
				rm -f "$MODDIR/mode"
				rm -f "$MODDIR/max_c"
				sed -i 's/\[.*\]/\[ 机型或系统可能不支持，无法使用，也可能有冲突，请排查移除冲突后重启再试 \]/g' "$MODDIR/module.prop"
				chattr -i -a '/data/vendor'
				chattr -R -i -a '/data/vendor/thermal'
				rm -rf '/data/vendor/thermal'
				sleep 1
			done
		fi
	fi
	rm -f '/data/vendor/thermal/config/mvt.conf'
	time_now="$(date +%s)"
	if [ "$time_mode" = "$(cat "$MODDIR/time_log" | sed -n '$p' | cut -d ' ' -f '2')" ]; then
		echo "$time_now $time_mode" >> "$MODDIR/time_log"
	else
		echo "$time_now $time_mode" > "$MODDIR/time_log"
	fi
	time_mode_n="$(cat "$MODDIR/time_log" | wc -l)"
	if [ "$time_mode_n" -gt "10" ]; then
		sed -i "1,$(( $time_mode_n - 10 ))d" "$MODDIR/time_log"
	fi
	time_mode_n="$(cat "$MODDIR/time_log" | wc -l)"
	if [ "$time_mode_n" = "10" ]; then
		time_s="$(cat "$MODDIR/time_log" | sed -n '1p' | cut -d ' ' -f '1')"
		if [ "$time_now" -lt "$(( $time_s + 120 ))" -a "$time_now" -gt "$time_s" ]; then
			while true ; do
				rm -f "$MODDIR/mode"
				rm -f "$MODDIR/max_c"
				rm -f "$MODDIR/time_log"
				sed -i 's/\[.*\]/\[ 有持续性第三方冲突，请排查移除冲突后重启再试 \]/g' "$MODDIR/module.prop"
				sleep 1
			done
		fi
	fi
}
bypass_supply_md5() {
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$md5_bypass" ]; then
		cp "$MODDIR/$t_bypass" "/data/vendor/thermal/config/thermal-normal.conf"
		if [ "$thermal_config_md5" != "$md5_bypass_0" -a "$thermal_config_md5" != "$md5_bypass_1" ]; then
			log_log=1
		fi
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	if [ ! -f "$MODDIR/mode" -o "$log_log" = "1" ]; then
		start_thermal_program
	fi
}
current_log() {
	current_txt="$(echo "$config_conf" | egrep '^current_txt=' | sed -n 's/current_txt=//g;$p')"
	if [ "$current_txt" = "1" ]; then
		current_n="$(cat "$MODDIR/current.txt" | wc -l)"
		if [ "$current_n" -gt "500" ]; then
			sed -i '1,50d' "$MODDIR/current.txt"
		fi
		battery_temp="$(cat '/sys/class/power_supply/battery/temp' | sed -n 's/.$//g;$p')"
		if [ "$stop_level" -gt "0" ]; then
			echo "$(date +%F_%T) $screen_data 电量$battery_level 档位$thermal_scene 电模$current_max 电流$now_current 温度$battery_temp $bypass_supply_type$stop_level" >> "$MODDIR/current.txt"
		else
			echo "$(date +%F_%T) $screen_data 电量$battery_level 档位$thermal_scene 电模$current_max 电流$now_current 温度$battery_temp" >> "$MODDIR/current.txt"
		fi
	fi
}
change_current() {
	if [ "$current_max" = "0" ]; then
		if [ -n "$now_current" ]; then
			echo "$now_current" >> "$MODDIR/now_c"
			now_current_n="$(cat "$MODDIR/now_c" | wc -l)"
			if [ "$now_current_n" -gt "10" ]; then
				sed -i '1,2d' "$MODDIR/now_c"
			fi
			now_current_e="$(cat "$MODDIR/now_c" | egrep '\-' | wc -l)"
			now_current_ev="$(cat "$MODDIR/now_c" | egrep -v '\-' | wc -l)"
			if [ "$now_current_e" -ge "5" -a "$now_current_ev" = "0" ]; then
				current_max="100000"
			else
				current_max="0"
			fi
		fi
	else
		rm -f "$MODDIR/now_c"
	fi
	current_log
	current_bridge="1000000"
	max_c="$(cat "$MODDIR/max_c")"
	battery_current_list="/sys/class/power_supply/battery/constant_charge_current_max /sys/class/power_supply/battery/constant_charge_current /sys/class/power_supply/battery/fast_charge_current /sys/class/power_supply/battery/thermal_input_current /sys/class/power_supply/battery/current_max"
	for i in $battery_current_list ; do
		if [ -f "$i" ]; then
			chmod 0644 "$i"
			battery_current_data="$(cat "$i")"
			if [ -n "$battery_current_data" -a "$battery_current_data" != "$current_max" ]; then
				if [ "$current_max" -ge "$current_bridge" -o "$battery_current_data" -ge "0" -o "$max_c" = "0" ]; then
					if [ "$current_max" -ge "$current_bridge" -o "$battery_current_data" -le "$current_bridge" ]; then
						echo "$current_max" > "$i"
					else
						echo "$current_bridge" > "$i"
					fi
				else
					echo "$current_bridge" > "$i"
				fi
			fi
		fi
	done
	if [ "$current_max" != "$max_c" ]; then
		echo "$current_max" > "$MODDIR/max_c"
	fi
}
stop_current() {
	if [ "$bypass_max" = "1" ]; then
		if [ -f "$MODDIR/stop_level" ]; then
			change_current
			rm -f "$MODDIR/stop_level"
		fi
		rm -f "$MODDIR/max_c"
	else
		if [ -f "$MODDIR/stop_level" ]; then
			rm -f "$MODDIR/stop_level"
		fi
	fi
}
bypass_supply_current() {
	if [ "$battery_level" -gt "0" ]; then
		until [ "$stop_level" -gt "0" ]; do
			stop_level="$battery_level"
			echo "$stop_level" > "$MODDIR/stop_level"
		done
		if [ "$battery_level" -lt "$stop_level" -o "$battery_level" -lt "3" ]; then
			md5_bypass="$md5_bypass_1"
			t_bypass='t_bypass_1'
		fi
		if [ "$bypass_max" = "1" ]; then
			if [ "$stop_level" = "100" ]; then
				if [ "$battery_level" = "100" ]; then
					current_max="0"
				elif [ "$battery_level" = "99" ]; then
					current_max="100000"
				fi
			else
				if [ "$battery_level" -gt "$stop_level" ]; then
					current_max="0"
				elif [ "$battery_level" = "$stop_level" ]; then
					current_max="100000"
				fi
			fi
			change_current
		else
			current_max="-"
			current_log
		fi
	fi
	bypass_supply_md5
}
bypass_supply_level_time() {
	bypass_level_data=1
	bypass_level_time_1="$(echo "$config_conf" | egrep '^bypass_level_time=' | sed -n 's/bypass_level_time=//g;$p' | cut -d ' ' -f '1')"
	bypass_level_time_2="$(echo "$config_conf" | egrep '^bypass_level_time=' | sed -n 's/bypass_level_time=//g;$p' | cut -d ' ' -f '2')"
	if [ "$bypass_level_time_1" != "$bypass_level_time_2" ]; then
		if [ "$bypass_level_time_1" -ge "0" -a "$bypass_level_time_1" -lt "24" -a "$bypass_level_time_2" -ge "0" -a "$bypass_level_time_2" -lt "24" ]; then
			if [ "$bypass_level_time_1" -gt "$bypass_level_time_2" ]; then
				if [ "$(date +%k)" -lt "$bypass_level_time_1" -a "$(date +%k)" -ge "$bypass_level_time_2" ]; then
					bypass_level_data=0
				fi
			elif [ "$bypass_level_time_1" -lt "$bypass_level_time_2" ]; then
				if [ "$(date +%k)" -lt "$bypass_level_time_1" -o "$(date +%k)" -ge "$bypass_level_time_2" ]; then
					bypass_level_data=0
				fi
			fi
		fi
	fi
}
bypass_supply_conf() {
	stop_level="$(cat "$MODDIR/stop_level")"
	battery_temp="$(cat '/sys/class/power_supply/battery/temp' | sed -n 's/.$//g;$p')"
	bypass_supply_temp_1="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p' | cut -d ' ' -f '1')"
	bypass_supply_temp_2="$(echo "$config_conf" | egrep '^bypass_supply_temp=' | sed -n 's/bypass_supply_temp=//g;$p' | cut -d ' ' -f '2')"
	if [ "$battery_temp" -gt "0" -a "$bypass_supply_temp_2" -gt "0" -a "$bypass_supply_temp_1" -gt "$bypass_supply_temp_2" ]; then
		if [ "$battery_temp" -ge "$bypass_supply_temp_1" ]; then
			if [ ! -f "$MODDIR/on_bypass_temp" ]; then
				touch "$MODDIR/on_bypass_temp"
			fi
		else
			if [ "$battery_temp" -le "$bypass_supply_temp_2" ]; then
				rm -f "$MODDIR/on_bypass_temp"
			fi
		fi
	else
		rm -f "$MODDIR/on_bypass_temp"
	fi
	if [ -f "$MODDIR/on_bypass_temp" ]; then
		bypass_supply_mode=1
	else
		if [ -f "$MODDIR/on_bypass" ]; then
			bypass_supply_mode=2
		else
			bypass_supply_level_time
			bypass_supply_level="$(echo "$config_conf" | egrep '^bypass_supply_level=' | sed -n 's/bypass_supply_level=//g;$p')"
			bypass_supply_level_2="$(( $bypass_supply_level - 1 ))"
			if [ "$battery_level" -ge "$bypass_supply_level" -a "$bypass_supply_level" -gt "2" -a "$bypass_supply_level" -le "100" -a "$bypass_level_data" = "1" ]; then
				bypass_supply_mode=3
			elif [ "$battery_level" = "$bypass_supply_level_2" -a "$bypass_supply_level" -gt "2" -a "$bypass_supply_level" -le "100" -a "$bypass_level_data" = "1" ]; then
				md5_bypass="$md5_bypass_1"
				t_bypass='t_bypass_1'
				bypass_supply_mode=3
			else
				if [ "$app_on" = "1" -a "$bypass_supply_app" = "1" ]; then
					bypass_supply_mode=4
				fi
			fi
		fi
	fi
	mode="$(cat "$MODDIR/mode")"
	if [ "$bypass_supply_mode" = "1" ]; then
		bypass_supply_type='温度旁路'
		time_mode=6
		bypass_supply_current
		if [ "$mode" != "6" ]; then
			echo "6" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：温度-旁路供电 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：温度-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "2" ]; then
		bypass_supply_type='手动旁路'
		time_mode=7
		bypass_supply_current
		if [ "$mode" != "7" ]; then
			echo "7" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：手动-旁路供电 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：手动-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "3" ]; then
		bypass_supply_type='电量旁路'
		time_mode=8
		bypass_supply_current
		if [ "$mode" != "8" ]; then
			rm -f "$MODDIR/stop_level"
			echo "8" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：电量-旁路供电 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：电量-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	elif [ "$bypass_supply_mode" = "4" ]; then
		bypass_supply_type='游戏旁路'
		time_mode=9
		bypass_supply_current
		if [ "$mode" != "9" ]; then
			echo "9" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：游戏-旁路供电 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：游戏-旁路供电" >> "$MODDIR/log.log"
		fi
		exit 0
	else
		if [ -f "$MODDIR/stop_level" ]; then
			rm -f "$MODDIR/stop_level"
		fi
	fi
}
t_blank_conf() {
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$md5_blank" ]; then
		cp "$MODDIR/t_blank" "/data/vendor/thermal/config/thermal-normal.conf"
		log_log=1
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "5" ]; then
		time_mode=5
		start_thermal_program
		echo "5" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：零档-无限制 \]/g' "$MODDIR/module.prop"
		echo "$(date +%F_%T) 当前温控：零档-无限制" >> "$MODDIR/log.log"
	fi
}
thermal_scene_conf() {
	thermal_scene_md5="$(md5sum "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | cut -d ' ' -f '1')"
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$thermal_scene_md5" ]; then
		cp "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" "/data/vendor/thermal/config/thermal-normal.conf"
		log_log=1
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$thermal_scene" = "1" ]; then
		if [ "$log_log" = "1" -o "$mode" != "11" ]; then
			time_mode=11
			start_thermal_program
			echo "11" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：一档-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：一档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "2" ]; then
		if [ "$log_log" = "1" -o "$mode" != "12" ]; then
			time_mode=12
			start_thermal_program
			echo "12" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：二档-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：二档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "3" ]; then
		if [ "$log_log" = "1" -o "$mode" != "13" ]; then
			time_mode=13
			start_thermal_program
			echo "13" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：三档-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：三档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "4" ]; then
		if [ "$log_log" = "1" -o "$mode" != "14" ]; then
			time_mode=14
			start_thermal_program
			echo "14" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：四档-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：四档-无限制" >> "$MODDIR/log.log"
		fi
	elif [ "$thermal_scene" = "5" ]; then
		if [ "$log_log" = "1" -o "$mode" != "15" ]; then
			time_mode=15
			start_thermal_program
			echo "15" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：五档-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：五档-无限制" >> "$MODDIR/log.log"
		fi
	else
		if [ "$log_log" = "1" -o "$mode" != "10" ]; then
			time_mode=10
			start_thermal_program
			echo "10" > "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 当前温控：其它-无限制 \]/g' "$MODDIR/module.prop"
			echo "$(date +%F_%T) 当前温控：其它-无限制" >> "$MODDIR/log.log"
		fi
	fi
}
thermal_app_conf() {
	thermal_app_md5="$(md5sum "$MODDIR/thermal/thermal-app.conf" | cut -d ' ' -f '1')"
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$thermal_app_md5" ]; then
		cp "$MODDIR/thermal/thermal-app.conf" "/data/vendor/thermal/config/thermal-normal.conf"
		log_log=1
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "4" ]; then
		time_mode=4
		start_thermal_program
		echo "4" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-app.conf \]/g' "$MODDIR/module.prop"
		echo "$(date +%F_%T) 当前温控：thermal-app.conf" >> "$MODDIR/log.log"
	fi
}
thermal_charge_conf() {
	thermal_charge_md5="$(md5sum "$MODDIR/thermal/thermal-charge.conf" | cut -d ' ' -f '1')"
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$thermal_charge_md5" ]; then
		cp "$MODDIR/thermal/thermal-charge.conf" "/data/vendor/thermal/config/thermal-normal.conf"
		log_log=1
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "3" ]; then
		time_mode=3
		start_thermal_program
		echo "3" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-charge.conf \]/g' "$MODDIR/module.prop"
		echo "$(date +%F_%T) 当前温控：thermal-charge.conf" >> "$MODDIR/log.log"
	fi
}
thermal_default_conf() {
	thermal_default_md5="$(md5sum "$MODDIR/thermal/thermal-default.conf" | cut -d ' ' -f '1')"
	thermal_config_md5="$(md5sum "/data/vendor/thermal/config/thermal-normal.conf" | cut -d ' ' -f '1')"
	if [ "$thermal_config_md5" != "$thermal_default_md5" ]; then
		cp "$MODDIR/thermal/thermal-default.conf" "/data/vendor/thermal/config/thermal-normal.conf"
		log_log=1
	fi
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep -i 'thermal\-' | egrep -i '\-map' | egrep -i -v '\-region\-map')"
	for i in $thermal_list ; do
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$i" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_config_md5" != "$md5_map" ]; then
			cp "$MODDIR/t_map" "/data/vendor/thermal/config/$i"
			log_log=1
		fi
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "2" ]; then
		time_mode=2
		start_thermal_program
		echo "2" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-default.conf \]/g' "$MODDIR/module.prop"
		echo "$(date +%F_%T) 当前温控：thermal-default.conf" >> "$MODDIR/log.log"
	fi
}
thermal_conf() {
	thermal_config="$(ls -A /data/vendor/thermal/config)"
	if [ -n "$thermal_config" ]; then
		delete_conf
		log_log=1
	fi
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "1" ]; then
		time_mode=1
		start_thermal_program
		echo "1" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：系统默认 \]/g' "$MODDIR/module.prop"
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
				service call SurfaceFlinger 1035 i32 "$DisplayModeRecord_id"
				if [ ! -f "$MODDIR/fps" ]; then
					touch "$MODDIR/fps"
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
					service call SurfaceFlinger 1035 i32 "$DisplayModeRecord_id"
				fi
			fi
		fi
		rm -f "$MODDIR/fps"
	fi
}
change_current_log() {
	if [ "$bypass_max" = "1" ]; then
		change_current
	else
		current_max="-"
		current_log
	fi
}
mode="$(cat "$MODDIR/mode")"
if [ "$mode" != 'stop' ]; then
	pgrep_thermal_program
fi
stat_decrypt_1="$(stat -c %Y '/data/vendor/thermal/decrypt.txt')"
global_switch="$(echo "$config_conf" | egrep '^global_switch=' | sed -n 's/global_switch=//g;$p')"
if [ -f "$MODDIR/disable" -o "$global_switch" = "0" ]; then
	mode="$(cat "$MODDIR/mode")"
	if [ "$mode" != 'stop' ]; then
		rm -f "$MODDIR/max_c"
		rm -f "$MODDIR/stop_level"
		rm -f "$MODDIR/now_c"
		thermal_conf
		echo 'stop' > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 模块已关闭 \]/g' "$MODDIR/module.prop"
		echo "$(date +%F_%T) 模块已关闭" >> "$MODDIR/log.log"
	fi
	exit 0
fi
bypass_supply_app="$(echo "$config_conf" | egrep '^bypass_supply_app=' | sed -n 's/bypass_supply_app=//g;$p')"
thermal_scene="$(echo "$config_conf" | egrep '^thermal_scene=' | sed -n 's/thermal_scene=//g;$p' | cut -d ' ' -f '1')"
screen_on="$(dumpsys deviceidle get screen)"
if [ "$screen_on" != 'false' ]; then
	screen_data=1
	thermal_app="$(echo "$config_conf" | egrep '^thermal_app=' | sed -n 's/thermal_app=//g;$p')"
	if [ "$thermal_app" = "1" ]; then
		app_list="$(echo "$config_conf" | egrep '^app_list=' | sed -n 's/app_list=//g;$p')"
		if [ -n "$app_list" ]; then
			dumpsys_window="$(dumpsys window displays | egrep 'mCurrentFocus' | sed -n '$p')"
			if [ -n "$dumpsys_window" ]; then
				activity_window="$(echo "$dumpsys_window" | egrep "$app_list")"
			else
				activity_window="$(dumpsys window | egrep 'mCurrentFocus' | sed -n '$p' | egrep "$app_list")"
			fi
			if [ -f "$MODDIR/mCurrentFocus" ]; then
				if [ ! -n "$activity_window" ]; then
					activity_window="$(dumpsys activity | egrep 'mResumedActivity|mTopFullscreen' | sed -n '$p' | egrep "$app_list")"
				fi
			fi
			if [ -n "$activity_window" ]; then
				if [ ! -f "$MODDIR/mCurrentFocus" ]; then
					touch "$MODDIR/mCurrentFocus"
				fi
				fps_lock
				dumpsys_charging="$(dumpsys deviceidle get charging)"
				if [ "$dumpsys_charging" = "true" ]; then
					app_on=1
					bypass_supply_conf
				else
					stop_current
				fi
				if [ "$bypass_supply_app" -gt "1" ]; then
					thermal_scene="$bypass_supply_app"
				fi
				thermal_app_c="$(cat "$MODDIR/thermal/thermal-app.conf" | wc -c)"
				if [ "$thermal_app_c" -lt "100" ]; then
					if [ "$thermal_scene" -ge "1" ]; then
						thermal_scene_c="$(cat "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | wc -c)"
						if [ "$thermal_scene_c" -lt "100" ]; then
							t_blank_conf
							thermal_scene="-"
						else
							thermal_scene_conf
						fi
					else
						t_blank_conf
					fi
				else
					thermal_app_conf
					thermal_scene="a"
				fi
				if [ "$app_on" = "1" ]; then
					change_current_log
				fi
				exit 0
			else
				rm -f "$MODDIR/mCurrentFocus"
			fi
		fi
	fi
else
	screen_data=0
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
			thermal_scene_time_data=0
			thermal_scene_time_1="$(echo "$config_conf" | egrep '^thermal_scene_time=' | sed -n 's/thermal_scene_time=//g;$p' | cut -d ' ' -f '1')"
			thermal_scene_time_2="$(echo "$config_conf" | egrep '^thermal_scene_time=' | sed -n 's/thermal_scene_time=//g;$p' | cut -d ' ' -f '2')"
			thermal_scene_time_3="$(echo "$config_conf" | egrep '^thermal_scene_time=' | sed -n 's/thermal_scene_time=//g;$p' | cut -d ' ' -f '3')"
			if [ "$thermal_scene_time_1" != "$thermal_scene_time_2" ]; then
				if [ "$thermal_scene_time_1" -ge "0" -a "$thermal_scene_time_1" -lt "24" -a "$thermal_scene_time_2" -ge "0" -a "$thermal_scene_time_2" -lt "24" -a "$thermal_scene_time_3" -ge "0" ]; then
					if [ "$thermal_scene_time_1" -gt "$thermal_scene_time_2" ]; then
						if [ "$(date +%k)" -ge "$thermal_scene_time_1" -o "$(date +%k)" -lt "$thermal_scene_time_2" ]; then
							thermal_scene="$thermal_scene_time_3"
							thermal_scene_time_data=1
						fi
					elif [ "$thermal_scene_time_1" -lt "$thermal_scene_time_2" ]; then
						if [ "$(date +%k)" -ge "$thermal_scene_time_1" -a "$(date +%k)" -lt "$thermal_scene_time_2" ]; then
							thermal_scene="$thermal_scene_time_3"
							thermal_scene_time_data=1
						fi
					fi
				fi
			fi
			if [ "$screen_data" = "0" -a "$thermal_scene_time_data" != "1" ]; then
				thermal_scene_rest="$(echo "$config_conf" | egrep '^thermal_scene=' | sed -n 's/thermal_scene=//g;$p' | cut -d ' ' -f '2')"
				if [ -n "$thermal_scene_rest" -a "$thermal_scene_rest" -ge "0" ]; then
					thermal_scene="$thermal_scene_rest"
				fi
			fi
			if [ "$thermal_scene" -ge "1" ]; then
				thermal_scene_c="$(cat "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" | wc -c)"
				if [ "$thermal_scene_c" -lt "100" ]; then
					t_blank_conf
					thermal_scene="-"
				else
					thermal_scene_conf
				fi
			else
				t_blank_conf
			fi
		else
			thermal_charge_conf
			thermal_scene="c"
		fi
		change_current_log
		exit 0
	fi
	thermal_scene="--"
	change_current_log
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
#version=2023032400
# ##

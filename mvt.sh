MODDIR=${0%/*}
log_log=0
log_n="$(cat "$MODDIR/log.log" | wc -l)"
if [ "$log_n" -gt "30" ]; then
	sed -i '1,5d' "$MODDIR/log.log" > /dev/null 2>&1
fi
config_conf="$(cat "$MODDIR/config.conf" | egrep -v '^#')"
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
	stop mi_thermald > /dev/null 2>&1
	stop thermal-engine > /dev/null 2>&1
	chattr -R -i -a '/data/vendor/thermal/'
	rm -f '/data/vendor/thermal/thermal.dump' > /dev/null 2>&1
	start mi_thermald > /dev/null 2>&1
	start thermal-engine > /dev/null 2>&1
	thermal_program_id="$(pgrep 'mi_thermald|thermal-engine')"
	if [ -n "$thermal_program_id" ]; then
		if [ ! -f '/data/vendor/thermal/thermal.dump' ]; then
			sleep 1
			dump_n=5
			until [ -f '/data/vendor/thermal/thermal.dump' -o "$dump_n" = "0" ] ; do
				sleep 1
				dump_n="$(( $dump_n - 1 ))"
			done
			if [ ! -f '/data/vendor/thermal/thermal.dump' ]; then
				while :;
				do
					rm -f "$MODDIR/mode" > /dev/null 2>&1
					sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则可能系统不支持MIUI云温控，也可能被第三方屏蔽或删除了，请排查温控相关的模块冲突，重启再试 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
					chattr -R -i -a '/data/vendor/thermal/'
					rm -rf '/data/vendor/thermal/' > /dev/null 2>&1
					sleep 1
				done
			fi
		fi
	else
		rm -f "$MODDIR/mode" > /dev/null 2>&1
		sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则系统温控程序被屏蔽或删除了，请恢复重启后再使用 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		exit 0
	fi
}
bypass_supply_md5() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$md5_bypass" ]; then
			cp "$MODDIR/t_bypass" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
}
bypass_supply_conf() {
	bypass_supply_mode=0
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
	fi
}
t_blank_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$md5_blank" ]; then
			cp "$MODDIR/t_blank" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
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
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$thermal_scene_md5" ]; then
			cp "$MODDIR/thermal/$thermal_scene/thermal-scene.conf" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
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
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$thermal_app_md5" ]; then
			cp "$MODDIR/thermal/thermal-app.conf" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
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
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$thermal_charge_md5" ]; then
			cp "$MODDIR/thermal/thermal-charge.conf" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
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
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$thermal_default_md5" ]; then
			cp "$MODDIR/thermal/thermal-default.conf" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "2" ]; then
		start_thermal_program
		echo "2" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：thermal-default.conf \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：thermal-default.conf" >> "$MODDIR/log.log"
	fi
}
thermal_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		thermal_vendor_md5="$(md5sum "/system/vendor/etc/$thermal_p" | cut -d ' ' -f '1')"
		thermal_config_md5="$(md5sum "/data/vendor/thermal/config/$thermal_p" | cut -d ' ' -f '1')"
		if [ -f "/system/vendor/etc/$thermal_p" -a "$thermal_config_md5" != "$thermal_vendor_md5" ]; then
			cp "/system/vendor/etc/$thermal_p" "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
			log_log=1
		fi
		thermal_n="$(( $thermal_n - 1 ))"
	done
	mode="$(cat "$MODDIR/mode")"
	if [ "$log_log" = "1" -o "$mode" != "1" ]; then
		start_thermal_program
		echo "1" > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 当前温控：系统默认 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 当前温控：系统默认" >> "$MODDIR/log.log"
	fi
}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf '/data/vendor/thermal/config/' > /dev/null 2>&1
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
	chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
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
		thermal_conf
		delete_conf
		echo 'stop' > "$MODDIR/mode"
		sed -i 's/\[.*\]/\[ 模块已关闭 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		echo "$(date +%F_%T) 模块已关闭" >> "$MODDIR/log.log"
		fps_recovery
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
#version=2022092600
# ##

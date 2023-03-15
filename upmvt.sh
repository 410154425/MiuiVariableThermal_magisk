MODDIR=${0%/*}
module_name="$(cat "$MODDIR/module.prop" | egrep 'name=' | sed -n 's/.*name=//g;s/(.*//g;1p')"
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;s/(.*//g;1p')"
Host_version="$(cat "$MODDIR/mvt.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
update_curl="http://z23r562938.iask.in/MVT_magisk"
up1="$(curl -s --connect-timeout 3 -m 5 "$update_curl/module.prop")"
up2="$(curl -s --connect-timeout 3 -m 5 "$update_curl/mvt.sh")"
if [ -f "$MODDIR/mode" ]; then
	if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
		echo -E "$up1" > "$MODDIR/module.prop" &&
		sed -i "s/^version=.*/version=${module_version}/g" "$MODDIR/module.prop"
		sed -i "s/^name=.*/name=${module_name}/g" "$MODDIR/module.prop"
		t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
		md5_blank="de59942d3dffc090f0dae74dfc4d47ce"
		if [ "$t_blank_md5" != "$md5_blank" ]; then
			curl -s --connect-timeout 3 -m 5 "$update_curl/t_blank" > "$MODDIR/thermal/t_blank"
			t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
		fi
		t_bypass_0_md5="$(md5sum "$MODDIR/thermal/t_bypass_0" | cut -d ' ' -f '1')"
		md5_bypass_0="006bb13431c52592192e710e46e76879"
		if [ "$t_bypass_0_md5" != "$md5_bypass_0" ]; then
			curl -s --connect-timeout 3 -m 5 "$update_curl/t_bypass_0" > "$MODDIR/thermal/t_bypass_0"
			t_bypass_0_md5="$(md5sum "$MODDIR/thermal/t_bypass_0" | cut -d ' ' -f '1')"
		fi
		t_bypass_1_md5="$(md5sum "$MODDIR/thermal/t_bypass_1" | cut -d ' ' -f '1')"
		md5_bypass_1="959b4f8711503653abea8a019936ab2c"
		if [ "$t_bypass_1_md5" != "$md5_bypass_1" ]; then
			curl -s --connect-timeout 3 -m 5 "$update_curl/t_bypass_1" > "$MODDIR/thermal/t_bypass_1"
			t_bypass_1_md5="$(md5sum "$MODDIR/thermal/t_bypass_1" | cut -d ' ' -f '1')"
		fi
		t_map_md5="$(md5sum "$MODDIR/thermal/t_map" | cut -d ' ' -f '1')"
		md5_map="43b4b914ef6b45119bbfe2030e4025a7"
		if [ "$t_map_md5" != "$md5_map" ]; then
			curl -s --connect-timeout 3 -m 5 "$update_curl/t_map" > "$MODDIR/thermal/t_map"
			t_map_md5="$(md5sum "$MODDIR/thermal/t_map" | cut -d ' ' -f '1')"
		fi
		if [ "$t_blank_md5" = "$md5_blank" -a "$t_bypass_0_md5" = "$md5_bypass_0" -a "$t_bypass_1_md5" = "$md5_bypass_1" -a "$t_map_md5" = "$md5_map" ]; then
			echo -E "$up2" > "$MODDIR/mvt.sh"
		fi
		module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
		if [ -n "$Host_version" -a "$Host_version" -lt "$module_versionCode" ]; then
			sed -i "s/^version=.*/version=${module_version}(有更新)/g" "$MODDIR/module.prop"
			sed -i "s/。 .*/。 \( 发现新版本，请到酷安或github.com搜作者动态下载更新 \)/g" "$MODDIR/module.prop"
		fi
		chmod 0755 "$MODDIR/mvt.sh"
		chmod 0644 "$MODDIR/module.prop"
		rm -f "$MODDIR/mode"
		rm -f "$MODDIR/time_log"
	fi
fi


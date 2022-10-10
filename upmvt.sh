MODDIR=${0%/*}
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;s/(.*//g;$p')"
Host_version="$(cat "$MODDIR/mvt.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
update_curl="http://z23r562938.iask.in/MVT_magisk"
up1="$(curl -s --connect-timeout 3 -m 5 "$update_curl/module.prop")"
up2="$(curl -s --connect-timeout 3 -m 5 "$update_curl/mvt.sh")"
if [ -f "$MODDIR/mode" ]; then
	if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
		echo -E "$up1" > "$MODDIR/module.prop" &&
		sed -i "s/version=.*/version=${module_version}/g" "$MODDIR/module.prop" > /dev/null 2>&1 ;
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_blank > "$MODDIR/thermal/t_blank"
		t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
		md5_blank="504b66ce8edee9842e487bd3adc5d158"
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_bypass_0 > "$MODDIR/thermal/t_bypass_0"
		t_bypass_0_md5="$(md5sum "$MODDIR/thermal/t_bypass_0" | cut -d ' ' -f '1')"
		md5_bypass_0="3790c1cbdf8d73fb1c028510bab1fe15"
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_bypass_1 > "$MODDIR/thermal/t_bypass_1"
		t_bypass_1_md5="$(md5sum "$MODDIR/thermal/t_bypass_1" | cut -d ' ' -f '1')"
		md5_bypass_1="b37574198e339747b06db2d3ce8346a1"
		if [ "$t_blank_md5" = "$md5_blank" -a "$t_bypass_0_md5" = "$md5_bypass_0" -a "$t_bypass_1_md5" = "$md5_bypass_1" ]; then
			echo -E "$up2" > "$MODDIR/mvt.sh"
		fi
		module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
		if [ -n "$Host_version" -a "$Host_version" -lt "$module_versionCode" ]; then
		sed -i "s/version=.*/version=${module_version}(有更新)/g" "$MODDIR/module.prop" > /dev/null 2>&1
		sed -i "s/。 .*/。 \( 发现新版本，请到酷安或github.com搜作者动态下载更新 \)/g" "$MODDIR/module.prop" > /dev/null 2>&1
		fi
		chmod 0755 "$MODDIR/mvt.sh"
		chmod 0644 "$MODDIR/module.prop"
		rm -f "$MODDIR/mode" > /dev/null 2>&1
	fi
fi

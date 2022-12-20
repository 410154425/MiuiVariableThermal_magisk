MODDIR=${0%/*}
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version=//g;s/(.*//g;$p')"
Host_version="$(cat "$MODDIR/mvt.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
update_curl="http://z23r562938.iask.in/MVT_magisk"
up1="$(curl -s --connect-timeout 3 -m 5 "$update_curl/module.prop")"
up2="$(curl -s --connect-timeout 3 -m 5 "$update_curl/mvt.sh")"
if [ -f "$MODDIR/mode" ]; then
	if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
		echo -E "$up1" > "$MODDIR/module.prop" &&
		sed -i "s/version=.*/version=${module_version}/g" "$MODDIR/module.prop"
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_blank > "$MODDIR/thermal/t_blank"
		t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
		md5_blank="20ace28f006f09d6c33394aee6f27474"
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_bypass_0 > "$MODDIR/thermal/t_bypass_0"
		t_bypass_0_md5="$(md5sum "$MODDIR/thermal/t_bypass_0" | cut -d ' ' -f '1')"
		md5_bypass_0="5dbb5f42dc87ba0bbf7ecefd227d1e49"
		curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_bypass_1 > "$MODDIR/thermal/t_bypass_1"
		t_bypass_1_md5="$(md5sum "$MODDIR/thermal/t_bypass_1" | cut -d ' ' -f '1')"
		md5_bypass_1="7d7e24f3a07669b61a165539dc5a4da1"
		if [ "$t_blank_md5" = "$md5_blank" -a "$t_bypass_0_md5" = "$md5_bypass_0" -a "$t_bypass_1_md5" = "$md5_bypass_1" ]; then
			echo -E "$up2" > "$MODDIR/mvt.sh"
		fi
		module_versionCode="$(cat "$MODDIR/module.prop" | egrep 'versionCode=' | sed -n 's/.*versionCode=//g;$p')"
		if [ -n "$Host_version" -a "$Host_version" -lt "$module_versionCode" ]; then
		sed -i "s/version=.*/version=${module_version}(有更新)/g" "$MODDIR/module.prop"
		sed -i "s/。 .*/。 \( 发现新版本，请到酷安或github.com搜作者动态下载更新 \)/g" "$MODDIR/module.prop"
		fi
		chmod 0755 "$MODDIR/mvt.sh"
		chmod 0644 "$MODDIR/module.prop"
		rm -f "$MODDIR/mode"
	fi
fi

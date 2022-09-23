MODDIR=${0%/*}
module_version="$(cat "$MODDIR/module.prop" | egrep 'version=' | sed -n 's/.*version\=//g;s/(.*//g;$p')"
Host_version="$(cat "$MODDIR/mvt.sh" | egrep '^#version=' | sed -n 's/.*version=//g;$p')"
update_curl="http://z23r562938.iask.in/MVT_magisk"
up1="$(curl -s --connect-timeout 3 -m 5 "$update_curl/module.prop")"
up2="$(curl -s --connect-timeout 3 -m 5 "$update_curl/mvt.sh")"
if [ "$(echo -E "$up1" | egrep '^# ##' | sed -n '$p')" = '# ##' -a "$(echo -E "$up2" | egrep '^# ##' | sed -n '$p')" = '# ##' ]; then
	echo -E "$up1" > "$MODDIR/module.prop" &&
	sed -i "s/version=.*/version=${module_version}/g" "$MODDIR/module.prop" > /dev/null 2>&1 ;
	curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_blank > "$MODDIR/thermal/t_blank"
	thermal_t_blank_md5="$(md5sum "$MODDIR/thermal/t_blank" | cut -d ' ' -f '1')"
	md5_blank="96797b0472c5f6c06ede5a3555d5e10a"
	curl -s --connect-timeout 3 -m 5 http://z23r562938.iask.in/MVT_magisk/t_bypass > "$MODDIR/thermal/t_bypass"
	thermal_t_bypass_md5="$(md5sum "$MODDIR/thermal/t_bypass" | cut -d ' ' -f '1')"
	md5_bypass="c3af0ba0b1cd16147e0fb919a9eea2b9"
	if [ "$thermal_t_blank_md5" = "$md5_blank" -a "$thermal_t_bypass_md5" = "$md5_bypass"	]; then
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

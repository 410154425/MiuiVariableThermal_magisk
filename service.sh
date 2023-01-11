until [ -f "${0%/*}/mvt.sh" ]; do
	rm -f "${0%/*}/mode"
	sed -i 's/\[.*\]/\[ 文件mvt.sh丢失，请重新安装模块重启 \]/g' "${0%/*}/module.prop"
	sleep 5
done
sleep 5
MODDIR=${0%/*}
chmod 0755 "$MODDIR/up"
chmod 0755 "$MODDIR/mvt.sh"
chmod 0755 "$MODDIR/upmvt.sh"
chmod 0755 "$MODDIR/testing.sh"
chmod 0644 "$MODDIR/config.conf"
echo "touch \"$MODDIR/on_bypass\"" > "$MODDIR/开启MIUI旁路供电.sh"
echo "rm -f \"$MODDIR/on_bypass\"" > "$MODDIR/关闭MIUI旁路供电.sh"
chmod 0755 "$MODDIR/开启MIUI旁路供电.sh"
chmod 0755 "$MODDIR/关闭MIUI旁路供电.sh"
echo "#执行该脚本，跳转微信网页给作者投币捐赠" > "$MODDIR/.投币捐赠.sh"
echo "am start -n com.tencent.mm/.plugin.webview.ui.tools.WebViewUI -d https://payapp.weixin.qq.com/qrpay/order/home2?key=idc_CHNDVI_dHFNbTNZIWMto44dgjR3CA-- > /dev/null 2>&1" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"\"" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"正在跳转MIUI动态温控捐赠页面，请稍等。。。\"" >> "$MODDIR/.投币捐赠.sh"
chmod 0755 "$MODDIR/.投币捐赠.sh"
until [ -d '/data/vendor/thermal/config/' ]; do
	rm -f "$MODDIR/mode"
	sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则可能系统不支持MIUI云温控，也可能被第三方屏蔽或删除了，请排查恢复系统温控后再使用 \]/g' "$MODDIR/module.prop"
	sleep 5
done
rm -f "$MODDIR/thermal_list"
until [ -f "$MODDIR/thermal_list" ]; do
	find /system/vendor/etc -type f -iname "thermal*.conf" | sed -n 's/\/system\/vendor\/etc\///g;p' | egrep -v '\/' > "$MODDIR/thermal_list"
	sleep 1
done
thermal_normal="$(cat "$MODDIR/thermal_list")"
thermal_normal_n="$(echo "$thermal_normal" | egrep -i 'thermal\-' | egrep -i -v '\-map' | wc -l)"
if [ "$thermal_normal_n" = "0" ]; then
	rm -f "$MODDIR/mode"
	sed -i 's/\[.*\]/\[ 没找到系统默认的温控文件，也可能系统不支持MIUI云温控，请排查恢复系统温控后再使用 \]/g' "$MODDIR/module.prop"
	exit 0
fi
map_c="$(cat '/system/vendor/etc/thermal-map.conf' | wc -c)"
normal_c="$(cat '/system/vendor/etc/thermal-normal.conf' | wc -c)"
devices_c="$(cat '/system/vendor/etc/thermald-devices.conf' | wc -c)"
if [ "$map_c" -lt "20" -o "$normal_c" -lt "20" -o "$devices_c" -lt "20" ]; then
	thermal_normal_n="$(echo "$thermal_normal" | egrep -i 'thermal')"
	for i in $thermal_normal_n ; do
		thermal_normal_c="$(cat "/system/vendor/etc/$i" | wc -c)"
		if [ -f "/system/vendor/etc/$i" -a "$thermal_normal_c" -lt "20" ]; then
			rm -f "$MODDIR/mode"
			sed -i 's/\[.*\]/\[ 系统温控文件被屏蔽了，请排查恢复系统温控后再使用 \]/g' "$MODDIR/module.prop"
			exit 0
		fi
	done
fi
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf /data/vendor/thermal/config/*
}
rm -f "$MODDIR/mode"
rm -f "$MODDIR/max_c"
rm -f "$MODDIR/stop_level"
rm -f "$MODDIR/now_c"
sed -i 's/\[.*\]/\[ 当前温控：-未知- \]/g' "$MODDIR/module.prop"
delete_conf
up=1
while true ; do
if [ "$up" = "20" -o "$up" = "7200" ]; then
	"$MODDIR/up" > /dev/null 2>&1 &
	up=21
fi
sleep 3
"$MODDIR/mvt.sh" > /dev/null 2>&1
up="$(( $up + 1 ))"
done

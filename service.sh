until [ -d "${0%/*}/" ] ; do
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
sed -i 's/\[.*\]/\[ 稍等！若提示超过1分钟，则可能系统不支持MIUI云温控，也可能被第三方屏蔽或删除了，请自行排查重启后再试 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
until [ -d '/data/vendor/thermal/' ] ; do
	sleep 1
done
find /system/vendor/etc -name "thermal*.conf" | egrep -i -v '\-map' | sed -n 's/\/system\/vendor\/etc\///g;p' | egrep -v '\/' > "$MODDIR/thermal_list"
sleep 1
thermal_normal="$(cat "$MODDIR/thermal_list")"
thermal_normal_n="$(echo "$thermal_normal" | egrep 'thermal\-' | wc -l)"
if [ "$thermal_normal_n" = "0" ]; then
	sed -i 's/\[.*\]/\[ 没找到MIUI系统默认的温控文件，也可能系统不支持MIUI云温控，请排查恢复后再使用 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
	exit 0
fi
thermal_normal_n="$(echo "$thermal_normal" | egrep 'thermal' | wc -l)"
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "/system/vendor/etc/$thermal_normal_p" | wc -c)"
	if [ "$thermal_normal_c" -lt "20" ]; then
		sed -i 's/\[.*\]/\[ MIUI系统温控文件可能被其它模块用空白文件屏蔽了，请排查温控相关的模块冲突，重启再使用 \]/g' "$MODDIR/module.prop" > /dev/null 2>&1
		exit 0
	fi
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
done
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf '/data/vendor/thermal/config/' > /dev/null 2>&1
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
	chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
}
rm -f "$MODDIR/mode" > /dev/null 2>&1
delete_conf
up=1
while :;
do
if [ "$up" = "20" -o "$up" = "7200" ]; then
	"$MODDIR/up" > /dev/null 2>&1 &
	up=21
fi
sleep 3
"$MODDIR/mvt.sh" > /dev/null 2>&1
up="$(( $up + 1 ))"
done

until [ $(getprop sys.boot_completed) -eq 1 ] ; do
  sleep 5
done
sleep 5
MODDIR=${0%/*}
chmod 0755 "$MODDIR/up"
chmod 0755 "$MODDIR/mvt.sh"
chmod 0755 "$MODDIR/upmvt.sh"
chmod 0644 "$MODDIR/config.conf"
sleep 1
up=1
echo "#执行该脚本，跳转微信网页给作者投币捐赠" > "$MODDIR/.投币捐赠.sh"
echo "am start -n com.tencent.mm/.plugin.webview.ui.tools.WebViewUI -d https://payapp.weixin.qq.com/qrpay/order/home2?key=idc_CHNDVI_dHFNbTNZIWMto44dgjR3CA-- >/dev/null 2>&1" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"\"" >> "$MODDIR/.投币捐赠.sh"
echo "echo \"正在跳转MIUI动态温控捐赠页面，请稍等。。。\"" >> "$MODDIR/.投币捐赠.sh"
chmod 0755 "$MODDIR/.投币捐赠.sh"
until [ -d "/system" ] ; do
  sleep 5
done
sleep 5
find /system/vendor/etc -name "thermal-*.conf" | egrep -i -v '\-map' | sed -n 's/\/system\/vendor\/etc\///g;p' | egrep -v '\/' > "$MODDIR/thermal_list"
sleep 1
thermal_normal="$(cat "$MODDIR/thermal_list")"
thermal_normal_n="$(echo "$thermal_normal" | wc -l)"
if [ "$thermal_normal_n" = "0" ]; then
	sed -i 's/\[.*\]/\[ 系统温控被删除，请恢复系统温控重启后再使用 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
	exit 0
fi
until [ "$thermal_normal_n" = "0" ] ; do
	thermal_normal_p="$(echo "$thermal_normal" | sed -n "${thermal_normal_n}p")"
	thermal_normal_c="$(cat "/system/vendor/etc/$thermal_normal_p" | wc -c)"
	if [ "$thermal_normal_c" -lt "20" ]; then
		sed -i 's/\[.*\]/\[ 系统温控被空文件屏蔽，请恢复系统温控重启后再使用 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
		exit 0
	fi
	thermal_normal_n="$(( $thermal_normal_n - 1 ))"
done
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
if [ "$data_vendor_thermal" != '/data/vendor/thermal/' ]; then
	sed -i 's/\[.*\]/\[ 云温控路径未适配，请联系作者适配 \]/g' "$MODDIR/module.prop" >/dev/null 2>&1
	exit 0
fi
if [ ! -d "/data/vendor/thermal/config" ]; then
	mkdir -p "/data/vendor/thermal/config" >/dev/null 2>&1
fi
chmod 0771 "/data/vendor/thermal" >/dev/null 2>&1
chmod 0771 "/data/vendor/thermal/config" >/dev/null 2>&1
chmod 0660 "/data/vendor/thermal/decrypt.txt" >/dev/null 2>&1
delete_conf() {
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		rm -f "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
		thermal_n="$(( $thermal_n - 1 ))"
	done
}
delete_conf
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

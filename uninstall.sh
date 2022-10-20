until [ -d "${0%/*}/" ] ; do
	sleep 5
done
sleep 3
MODDIR=${0%/*}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	thermal_config="$(ls -A /data/vendor/thermal/config)"
	for i in $thermal_config ; do
		rm -rf "/data/vendor/thermal/config/$i" > /dev/null 2>&1
	done
}
if [ -d '/data/vendor/thermal/config/' ]; then
delete_conf
fi

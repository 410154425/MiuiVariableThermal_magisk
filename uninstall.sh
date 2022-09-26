until [ -d "${0%/*}/" ] ; do
	sleep 5
done
sleep 3
MODDIR=${0%/*}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf '/data/vendor/thermal/config/' > /dev/null 2>&1
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
	chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
}
if [ -d '/data/vendor/thermal/' ]; then
delete_conf
fi

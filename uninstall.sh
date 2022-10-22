until [ -d "${0%/*}/" ] ; do
	sleep 5
done
sleep 3
MODDIR=${0%/*}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf /data/vendor/thermal/config/*
}
if [ -d '/data/vendor/thermal/config/' ]; then
	delete_conf
fi

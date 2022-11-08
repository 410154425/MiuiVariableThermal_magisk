until [ -d "${0%/*}/" ] ; do
	sleep 5
done
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal/'
	rm -rf /data/vendor/thermal/config/*
}
if [ -d '/data/vendor/thermal/config/' ]; then
	delete_conf
	echo "$(date +%F_%T)" > '/data/vendor/thermal/config/mvt.conf'
	sleep 3
	rm -f '/data/vendor/thermal/config/mvt.conf'
fi

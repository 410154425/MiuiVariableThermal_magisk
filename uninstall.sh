MODDIR=${0%/*}
delete_conf() {
	chattr -R -i -a '/data/vendor/thermal'
	thermal_list="$(cat "$MODDIR/thermal_list" | egrep 'thermal\-')"
	thermal_n="$(echo "$thermal_list" | egrep 'thermal\-' | wc -l)"
	until [ "$thermal_n" = "0" ] ; do
		thermal_p="$(echo "$thermal_list" | sed -n "${thermal_n}p")"
		rm -f "/data/vendor/thermal/config/$thermal_p" > /dev/null 2>&1
		thermal_n="$(( $thermal_n - 1 ))"
	done
	rm -rf '/data/vendor/thermal/config/' > /dev/null 2>&1
	mkdir -p '/data/vendor/thermal/config/' > /dev/null 2>&1
	chmod -R 0771 '/data/vendor/thermal/' > /dev/null 2>&1
}
delete_conf

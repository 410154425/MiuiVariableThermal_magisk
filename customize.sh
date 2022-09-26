chmod 0000 '/data/adb/modules/MiuiVariableThermal/mvt.sh' > /dev/null 2>&1
ui_print " -------------------------- "
ui_print " ------ 安装中，请稍等 ------ "
sleep 1
ui_print " -------------------------- "
sleep 1
ui_print " -------------------------- "
sleep 1
chattr -R -i -a '/data/vendor/thermal/' > /dev/null 2>&1
rm -rf '/data/vendor/thermal/' > /dev/null 2>&1
ui_print " ----- 安装已完成，请重启 ---- "
ui_print " -------------------------- "

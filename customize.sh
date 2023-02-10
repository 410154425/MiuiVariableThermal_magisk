chmod 0000 '/data/adb/modules/MiuiVariableThermal/mvt.sh'
cp "$MODPATH/module.prop" "$MODPATH/t_module"
ui_print " -------------------------- "
ui_print " ------ 安装中，请稍等 ------ "
sleep 1
ui_print " -------------------------- "
sleep 1
ui_print " -------------------------- "
sleep 1
chattr -R -i -a '/data/vendor/thermal/'
rm -rf '/data/vendor/thermal/'
ui_print " ----- 安装已完成，请重启 ---- "
ui_print " -------------------------- "

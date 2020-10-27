#!/bin/bash

function update_package(){
sed -i "/dvb_package=/c\dvb_package=${1}" "/boot/config/plugins/dvb-driver/settings.cfg"
}

$@

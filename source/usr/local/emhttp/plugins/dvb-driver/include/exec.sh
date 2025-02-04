#!/bin/bash
echo
# Set Variables
KERNEL_V="$(uname -r)"
DL_URL="https://github.com/unraid/unraid-dvb-driver/releases/download/$KERNEL_V"
LAT_PACKAGE="$(wget -qO- https://api.github.com/repos/unraid/unraid-dvb-driver/releases/tags/${KERNEL_V} | jq -r '.assets[].name' | grep "${1}" | grep -E -v '\.md5$' | sort -V | tail -1)"

if [ "${1}" == "$(cat /boot/config/plugins/dvb-driver/settings.cfg | grep "dvb_package=" | cut -d '=' -f2)" ]; then
  echo "---Please wait, downloading new version from ${1}-DVB-Driver-Package---"
  rm -rf /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${1}*
else
  echo "-----------Please wait, downloading ${1}-DVB-Driver-Package------------"
fi

# Download driver
if wget -q -nc -O "/boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}" "${DL_URL}/${LAT_PACKAGE}" ; then
  wget -q -nc -O "/boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5" "${DL_URL}/${LAT_PACKAGE}.md5"
  if [ "$(md5sum /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE} | awk '{print $1}')" != "$(cat /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}.md5 | awk '{print $1}')" ]; then
    echo
    echo "---CHECKSUM ERROR!---"
    rm -rf /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}*
    exit 1
  fi
  echo
  echo "-----------Successfully downloaded ${1}-DVB-Driver-Package-------------"
  echo "--------------Please reboot your server to install it!-----------------"
  sed -i "/dvb_package=/c\dvb_package=${1}" "/boot/config/plugins/dvb-driver/settings.cfg"
  rm -rf $(ls -d /boot/config/plugins/dvb-driver/packages/* | grep -v "${KERNEL_V%%-*}")
  rm -rf $(find /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/ -type f -maxdepth 1 | grep -v "${1}")
  /usr/local/emhttp/plugins/dynamix/scripts/notify -e "DVB Driver Installation" -d "Please restart your server to complete the installation from the ${1} DVB Package ATTENTION: Please update your 'go' file if the plugin doesn't load the Kernel Module correctly for you DVB card, for more information see the DVB Plugin page." -i "alert" -l "Main"
else
  echo
  echo "---------------Can't download ${1}-DVB-Driver-Package------------------"
  rm -rf /boot/config/plugins/dvb-driver/packages/${KERNEL_V%%-*}/${LAT_PACKAGE}*
  exit 1
fi

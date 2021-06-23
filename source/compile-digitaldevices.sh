# Create necessary directories and download source
cd ${DATA_DIR}
mkdir ${DATA_DIR}/dd-master
if [ -f ${DATA_DIR}/dd-master.tar.gz ]; then
	rm -rf ${DATA_DIR}/dd-master.tar.gz
fi
wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/dd-master.tar.gz https://github.com/DigitalDevices/dddvb/archive/master.tar.gz
tar -C ${DATA_DIR}/dd-master --strip-components=1 -xf ${DATA_DIR}/dd-master.tar.gz
cd ${DATA_DIR}/dd-master
DD_DRV_V="$(cat ${DATA_DIR}/dd-master/ddbridge/ddbridge.h | grep "DDBRIDGE_VERSION" | cut -d '"' -f2)"
if [ ! -f ${DATA_DIR}/dd-v${DRV_V}.tar.gz ]; then
	mv ${DATA_DIR}/dd-master.tar.gz ${DATA_DIR}/dd-v${DRV_V}.tar.gz
else
	rm -rf ${DATA_DIR}/dd-master.tar.gz
fi

# Compile DigitialDevices modules and install them to temporary directory
make -j${CPU_COUNT}
make INSTALL_MOD_PATH=/digital_devices install -j${CPU_COUNT}

# Cleanup modules directory
cd /digital_devices/lib/modules/${UNAME}
rm /digital_devices/lib/modules/${UNAME}/* 2>/dev/null
find . -depth -exec rmdir {} \;  2>/dev/null

# Create Slackware package
PLUGIN_NAME="digitaldevices"
BASE_DIR="/digital_devices"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME DVB driver v$DD_DRV_V
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME DVB driver package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5
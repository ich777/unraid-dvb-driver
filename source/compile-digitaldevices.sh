# Create necessary directories and download source from Github
cd ${DATA_DIR}
mkdir -p ${DATA_DIR}/dd-master
cd ${DATA_DIR}/dd-master

git clone https://github.com/DigitalDevices/dddvb
cd ${DATA_DIR}/dd-master/dddvb
git checkout master
DD_DRV_V="$(git log -1 --format="%cs" | sed 's/-//g')"
sed -i '/$(MAKE) -C app/s/^/# /' ${DATA_DIR}/dd-master/dddvb/Makefile

# Compile drivers and move them to temporary directory
make -j${CPU_COUNT}
make MDIR=/digital_devices install -j${CPU_COUNT}

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
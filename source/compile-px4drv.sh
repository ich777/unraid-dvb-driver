# Create necessary directories and download source
cd ${DATA_DIR}
PX4DRV_BRANCH="develop"
mkdir -p /PX4DRV/lib/firmware /PX4DRV/lib/modules/$UNAME/extra/px4drv

# Clone PX4DRV driver, extact Firmware and put it into temporary directory
git clone https://github.com/nns779/px4_drv
cd ${DATA_DIR}/px4_drv
git checkout ${PX4DRV_BRANCH}
cd ${DATA_DIR}/px4_drv/fwtool
make -j${CPU_COUNT}
if [ ! -f ${DATA_DIR}/pxw3u4_BDA_ver1x64.zip ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/pxw3u4_BDA_ver1x64.zip http://plex-net.co.jp/plex/pxw3u4/pxw3u4_BDA_ver1x64.zip
fi
unzip -oj ${DATA_DIR}/pxw3u4_BDA_ver1x64.zip pxw3u4_BDA_ver1x64/PXW3U4.sys
${DATA_DIR}/px4_drv/fwtool/fwtool ${DATA_DIR}/px4_drv/fwtool/PXW3U4.sys /PX4DRV/lib/firmware/it930x-firmware.bin

# Compile PX4DRV module and put it into temporary directory
cd ${DATA_DIR}/px4_drv/driver
make -j${CPU_COUNT}
cp ${DATA_DIR}/px4_drv/driver/*.ko /PX4DRV/lib/modules/${UNAME}/extra/px4drv

# Compress modules
while read -r line
do
  xz --check=crc32 --lzma2 $line
done < <(find /PX4DRV/lib/modules/$UNAME/extra/px4drv -name "*.ko")

# Create Slackware package
PLUGIN_NAME="px4drv"
BASE_DIR="/PX4DRV"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: Plex PX Series Tuners driver from latest ${PX4DRV_BRANCH} branch
$PLUGIN_NAME:
$PLUGIN_NAME: Source: https://github.com/nns779/px4_drv
$PLUGIN_NAME:
$PLUGIN_NAME: Custom Plex PX Series Tuners driver package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5
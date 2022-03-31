# Create necessary directories and download source
cd ${DATA_DIR}
mkdir ${DATA_DIR}/TBS_OS
mkdir -p /tbs-os/lib/firmware
mkdir -p /tbs-os/lib/modules/${UNAME}
cd ${DATA_DIR}/TBS_OS
git clone https://github.com/tbsdtv/media_build.git
git clone --depth=1 https://github.com/tbsdtv/linux_media.git -b latest ./media
cd ${DATA_DIR}/TBS_OS/media_build

# Compile TBS-OpenSource modules and install them to temporary directory
make dir DIR=../media
make allyesconfig
make -j${CPU_COUNT} -i
DESTDIR=/tbs-os make install -j${CPU_COUNT}

#Compress modules
while read -r line
do
	xz --check=crc32 --lzma2 $line
done < <(find /tbs-os/lib/modules/${UNAME}/kernel -name "*.ko")

#Download and decompress Firmwares
if [ ! -f ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 http://www.tbsdtv.com/download/document/linux/tbs-tuner-firmwares_v1.0.tar.bz2
fi
tar jxvf ${DATA_DIR}/tbs-tuner-firmwares_v1.0.tar.bz2 -C /tbs-os/lib/firmware

#Download and decompress Firmwares for CX24117
if [ ! -f ${DATA_DIR}/tbs-linux-drivers_v130901.zip ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/tbs-linux-drivers_v130901.zip http://www.tbsdtv.com/download/document/common/tbs-linux-drivers_v130901.zip
fi
if [ ! -f /tbs-os/lib/firmware/dvb-fe-cx24117.fw ]; then
  unzip -p tbs-linux-drivers_v130901.zip linux-tbs-drivers.tar.bz2 | tar jxOf - linux-tbs-drivers/v4l/tbs6981fe_driver.o.x86_64 | dd bs=1 skip=10144 count=55486 of=/tbs-os/lib/firmware/dvb-fe-cx24117.fw
fi

#Download firmware for USB Tuner Mygica T230A
if [ ! -f ${DATA_DIR}/dvb-tuner-si2141-a10-01.tar.gz ]; then
  wget -q -nc --show-progress --progress=bar:force:noscroll -O ${DATA_DIR}/dvb-tuner-si2141-a10-01.fw https://github.com/osmc/dvb-firmware-osmc/raw/master/dvb-tuner-si2141-a10-01.fw
  tar -czvf ${DATA_DIR}/dvb-tuner-si2141-a10-01.tar.gz -C ${DATA_DIR} dvb-tuner-si2141-a10-01.fw
  rm -f ${DATA_DIR}/dvb-tuner-si2141-a10-01.fw
fi
if [ ! -f /tbs-os/lib/firmware/dvb-tuner-si2141-a10-01.fw ]; then
  tar xzvf ${DATA_DIR}/dvb-tuner-si2141-a10-01.tar.gz -C /tbs-os/lib/firmware
fi

# Cleanup modules directory
cd /tbs-os/lib/modules/${UNAME}/
rm /tbs-os/lib/modules/${UNAME}/* 2>/dev/null
find . -depth -exec rmdir {} \;  2>/dev/null

# Create Slackware package
PLUGIN_NAME="tbsos"
BASE_DIR="/tbs-os"
TMP_DIR="/tmp/${PLUGIN_NAME}_"$(echo $RANDOM)""
VERSION="$(date +'%Y.%m.%d')"

mkdir -p $TMP_DIR/$VERSION
cd $TMP_DIR/$VERSION
cp -R $BASE_DIR/* $TMP_DIR/$VERSION/
mkdir $TMP_DIR/$VERSION/install
tee $TMP_DIR/$VERSION/install/slack-desc <<EOF
       |-----handy-ruler------------------------------------------------------|
$PLUGIN_NAME: $PLUGIN_NAME DVB driver v$TBS_MEDIA_BUILD_V
$PLUGIN_NAME:
$PLUGIN_NAME:
$PLUGIN_NAME: Custom $PLUGIN_NAME DVB driver package for Unraid Kernel v${UNAME%%-*} by ich777
$PLUGIN_NAME:
EOF
${DATA_DIR}/bzroot-extracted-$UNAME/sbin/makepkg -l n -c n $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz
md5sum $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz | awk '{print $1}' > $TMP_DIR/$PLUGIN_NAME-plugin-$UNAME-1.txz.md5
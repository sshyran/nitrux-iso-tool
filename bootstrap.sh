#! /bin/sh

export LANG=C
export LC_ALL=C


# -- Packages to install.

PACKAGES='
dhcpcd5
user-setup
localechooser-data
cifs-utils
casper
lupin-casper
nomad-desktop
'

# -- Install basic packages.

apt -qq update > /dev/null
apt -yy -qq install apt-transport-https wget ca-certificates gnupg2 apt-utils --no-install-recommends > /dev/null


# -- Use optimized sources.list. The LTS repositories are used to support the KDE Neon repository since these
# -- packages are built against the latest LTS release of Ubuntu.

wget -q https://archive.neon.kde.org/public.key -O neon.key
echo ee86878b3be00f5c99da50974ee7c5141a163d0e00fccb889398f1a33e112584 neon.key | sha256sum -c &&
	apt-key add neon.key

wget -q http://repo.nxos.org/public.key -O nxos.key
echo b51f77c43f28b48b14a4e06479c01afba4e54c37dc6eb6ae7f51c5751929fccc nxos.key | sha256sum -c &&
	apt-key add nxos.key

# -- Add key for the Graphics Driver PPA
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1118213C

# -- Add key for the Ubuntu-X PPA
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AF1CDFA9

rm neon.key
rm nxos.key

cp /configs/sources.list /etc/apt/sources.list


# -- Update packages list and install packages. Install Nomad Desktop meta package and base-files package
# -- avoiding recommended packages.

apt -qq update > /dev/null
apt -yy install $(echo $PACKAGES | tr '\n' ' ') --no-install-recommends > /dev/null
apt -yy -qq upgrade > /dev/null
apt -qq clean 
apt -qq autoclean


# -- Add AppImages.

APPS='
https://github.com/Nitrux/znx/releases/download/continuous/znx
https://raw.githubusercontent.com/UriHerrera/storage/master/VLC-3.0.0.gitfeb851a.glibc2.17-x86-64.AppImage
https://raw.githubusercontent.com/UriHerrera/storage/master/ungoogled-chromium_70.0.3538.77-1_linux.AppImage
https://libreoffice.soluzioniopen.com/stable/fresh/LibreOffice-fresh.basic-x86_64.AppImage
'

mkdir /Applications

for x in $(echo $APPS | tr '\n' ' '); do
	wget -q -P /Applications $x
done

chmod +x /Applications/*



# -- Create /Applications dir for users. This dir "should" be created by the Software Center.
# -- Downloading AppImages with the SC will fail if this dir doesn't exist.

mkdir /etc/skel/Applications


# -- Add AppImages to the user /Applications dir.

cp -a /Applications/*.AppImage /etc/skel/Applications
rm /Applications/*.AppImage


# -- Add znx-gui.

cp /configs/znx-gui.desktop /usr/share/applications
wget -q https://raw.githubusercontent.com/Nitrux/znx-gui/master/znx-gui -O /bin/znx-gui
chmod +x /bin/znx-gui


# -- Install the latest stable kernel.

kfiles='
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.1/linux-headers-4.19.1-041901_4.19.1-041901.201811041431_all.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.1/linux-headers-4.19.1-041901-generic_4.19.1-041901.201811041431_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.1/linux-image-unsigned-4.19.1-041901-generic_4.19.1-041901.201811041431_amd64.deb
http://kernel.ubuntu.com/~kernel-ppa/mainline/v4.19.1/linux-modules-4.19.1-041901-generic_4.19.1-041901.201811041431_amd64.deb
'

mkdir latest_kernel

for x in $kfiles; do
	wget -q -P latest_kernel $x
done

dpkg -iR latest_kernel
rm -r latest_kernel


# -- Install Maui Apps Debs.

mauipkgs='
https://raw.githubusercontent.com/UriHerrera/storage/master/mauikit-framework_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/vvave_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/pix_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/index_0.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/buho_0.1-1_amd64.deb
'

mkdir maui_debs

for x in $mauipkgs; do
	wget -q -P maui_debs $x
done

dpkg --force-all -iR maui_debs > /dev/null
rm -r maui_debs


# -- Install Software Center.
# -- For now, the software center, libappimage and libappimageinfo provide the same library
# -- and to install each package the library must be overwritten each time.

nxsc='
https://raw.githubusercontent.com/UriHerrera/storage/master/libappimageinfo_0.1.1-1_amd64.deb
https://raw.githubusercontent.com/UriHerrera/storage/master/nx-software-center-plasma_2.3-2_amd64.deb
'

mkdir nxsc_deps

for x in $nxsc; do
	wget -q -P nxsc_deps $x
done

dpkg --force-all -iR nxsc_deps > /dev/null
rm -r nxsc_deps

ln -sv /usr/lib/x86_64-linux-gnu/libbfd-2.30-multiarch.so /usr/lib/x86_64-linux-gnu/libbfd-2.31.1-multiarch.so
ln -sv /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_filesystem.so.1.67.0
ln -sv /usr/lib/x86_64-linux-gnu/libboost_system.so.1.65.1 /usr/lib/x86_64-linux-gnu/libboost_system.so.1.67.0

# -- Install AppImage daemon. AppImages that are downloaded to the dirs monitored by the daemon should be integrated automatically.
# -- firejail should be automatically used by the daemon to sandbox AppImages.

appimgd='
https://github.com/AppImage/appimaged/releases/download/continuous/appimaged_1-alpha-git189b800.travis42_amd64.deb
'

mkdir appimaged_deb

for x in $appimgd; do
	wget -q -P appimaged_deb $x
done

dpkg -iR appimaged_deb > /dev/null
rm -r appimaged_deb


# -- Add /Applications to $PATH.

printf "PATH=$PATH:/Applications\n" > /etc/environment
sed -i "s|secure_path\=.*$|secure_path=\"$PATH:/Applications\"|g" /etc/sudoers
sed -i "/env_reset/d" /etc/sudoers

# -- Add config for SDDM.

cp /configs/sddm.conf /etc


# -- Modify the initramfs code.

cat /configs/persistence >> /usr/share/initramfs-tools/scripts/casper-bottom/05mountpoints_lupin
cat /configs/update-image >> /usr/share/initramfs-tools/scripts/casper-premount/20iso_scan
update-initramfs -u


# -- Fix for https://bugs.launchpad.net/ubuntu/+source/network-manager/+bug/1638842.

cp /configs/10-globally-managed-devices.conf /etc/NetworkManager/conf.d/

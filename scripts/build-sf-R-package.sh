#### build-sf-R-package.sh v1.2
# Build and install the "Simple Features for R" package
# (https://github.com/r-spatial/sf) and dependencies from source
#

#############################################################
# Disclaimer
#############################################################
#
# This is provided as-is without support and may not work due to
# differences on your system.
#
# No liability for the contents of this documents can be accepted. Use
# the concepts, examples and other content at your own risk. There may
# be errors and inaccuracies, that may of course be damaging to your
# system. Although this is highly unlikely, you should proceed with
# caution. The author does not accept any responsibility for any
# damage incurred.
#
# All copyrights are held by their respective owners, unless
# specifically noted otherwise. Use of a term in this document should
# not be regarded as affecting the validity of any trademark or
# service mark.
#
# Naming of particular products or brands should not be seen as
# endorsements.
#
#############################################################

# Build system/compiler
# CentOS Linux release 7.9.2009 (Core)
# gcc (GCC) 7.3.1 20180303 (Red Hat 7.3.1-5)

## OS setup
# HN=
# hostname $HN
# echo $HN > /etc/hostname
# cat /etc/hostname
# reboot

## Redhat Enterprise Linux 7 Subscription
# subscription-manager register
# subscription-manager attach

## Redhat Enterprise Linux 7 Build R
# sudo yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# sudo subscription-manager repos --enable "rhel-*-optional-rpms"
# sudo subscription-manager repos --disable rhel-7-server-e4s-optional-rpms
# sudo subscription-manager repos --disable rhel-7-server-eus-optional-rpm
# sudo yum-builddep R -y
# export R_VERSION=4.0.2
# curl -O https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm
# sudo yum install R-${R_VERSION}-1-1.x86_64.rpm

#install newer gcc with devtoolset
#if ! rpm -q centos-release-scl > /dev/null ; then
#    sudo yum install centos-release-scl
#fi

## openssl for cmake
# sudo yum install openssl-devel

# #needed for units
# sudo yum install udunits2-devel

## Redhat Enterprise Linux 7 devtoolset
# subscription-manager list --available
# subscription-manager list --available | grep "Pool ID:"
# POOLID=subscription-manager list --available | awk '/Pool ID:/{ print $NF}'
# subscription-manager attach --pool=$POOLID
# subscription-manager repos --list | grep devtools
# subscription-manager repos --enable rhel-7-server-devtools-rpms

# if ! rpm -q devtoolset-7 > /dev/null; then
#     sudo yum install devtoolset-7
# fi

# gcc version 7.3.1 20180303 (Red Hat 7.3.1-5) (GCC)
source scl_source enable devtoolset-7

# sets the build dir
BUILD_ROOT=/data/sf-build

#keep track of env vars
SFVARS=$BUILD_ROOT/sf-build-vars
echo \# $(date) > $SFVARS

SOURCE_DIR=${BUILD_ROOT}/source
DOWNLOAD_DIR=${BUILD_ROOT}/download
mkdir -vp ${BUILD_ROOT} ${SOURCE_DIR} ${DOWNLOAD_DIR}

# sets the install path
#INSTALL_PATH=/opt/sf-package
INSTALL_PATH=/opt/sf-package

sudo mkdir -v ${INSTALL_PATH}
cd ${DOWNLOAD_DIR}

echo "BUILD_ROOT=/data/sf-build" >> $SFVARS
echo "SOURCE_DIR=${BUILD_ROOT}/source" >> $SFVARS
echo "DOWNLOAD_DIR=${BUILD_ROOT}/download" >> $SFVARS
echo "INSTALL_PATH=/opt/sf-package" >> $SFVARS

#############################################################
### Downloads
#############################################################
wget https://github.com/Kitware/CMake/releases/download/v3.27.6/cmake-3.27.6.tar.gz
wget https://github.com/OSGeo/gdal/releases/download/v3.7.2/gdal-3.7.2.tar.gz
curl -O https://download.osgeo.org/geos/geos-3.12.0.tar.bz2
curl -O https://download.osgeo.org/proj/proj-9.3.0.tar.gz
#proj data if needed
curl -O https://download.osgeo.org/proj/proj-data-1.15.tar.gz
curl -O https://sqlite.org/2023/sqlite-autoconf-3430100.tar.gz
wget --no-proxy https://sqlite.org/2023/sqlite-autoconf-3430100.tar.gz
wget https://cran.r-project.org/src/contrib/sf_1.0-14.tar.gz

#############################################################
### cmake https://cmake.org/
#############################################################
CMAKE_VER="cmake-3.27.6"
CMAKE_PREFIX=${INSTALL_PATH}/${CMAKE_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/${CMAKE_VER}.tar.gz  && cd ${SOURCE_DIR}/cmake-*
./bootstrap --prefix=${CMAKE_PREFIX}
gmake
sudo make install
export PATH="${CMAKE_PREFIX}/bin:$PATH"
cmake --version

echo CMAKE_VER="cmake-3.27.6" >> $SFVARS
echo "CMAKE_PREFIX=${INSTALL_PATH}/${CMAKE_VER}" >> $SFVARS
echo PATH="$PATH" >> $SFVARS

#############################################################
### sqlite https://sqlite.org/index.html
#############################################################
SQLITE_VER="sqlite-3.43.1"
SQLITE_PREFIX=${INSTALL_PATH}/${SQLITE_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/sqlite-autoconf-3430100.tar.gz  && cd ${SOURCE_DIR}/sqlite-autoconf-*
CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1"
./configure --prefix=${SQLITE_PREFIX}
make
sudo make install
export PATH=${SQLITE_PREFIX}/bin:$PATH
sqlite3 --version

echo SQLITE_VER="sqlite-3.43.1" >> $SFVARS
echo "SQLITE_PREFIX=${INSTALL_PATH}/${SQLITE_VER}" >> $SFVARS
echo PATH="$PATH" >> $SFVARS

#############################################################
### proj (requires cmake/sqlite3) https://proj.org/index.html
#############################################################
PROJ_VER="proj-9.3.0"
PROJ_PREFIX=${INSTALL_PATH}/${PROJ_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/proj-9.3.0.tar.gz  && cd ${SOURCE_DIR}/proj-*
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH="${SQLITE_PREFIX}" -DCMAKE_INSTALL_PREFIX="${PROJ_PREFIX}" ..
cmake --build .
sudo cmake --build . --target install
export PATH=${PROJ_PREFIX}/bin:$PATH
proj --version

echo PROJ_VER="proj-9.3.0" >> $SFVARS
echo "PROJ_PREFIX=${INSTALL_PATH}/${PROJ_VER}" >> $SFVARS
echo PATH="$PATH" >> $SFVARS

#############################################################
### geos https://libgeos.org
#############################################################
GEOS_VER="geos-3.12.0"
GEOS_PREFIX=${INSTALL_PATH}/${GEOS_VER}
tar -C ${SOURCE_DIR} -xvjf ${DOWNLOAD_DIR}/geos-3.12.0.tar.bz2  && cd ${SOURCE_DIR}/geos-*
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX="${GEOS_PREFIX}" ..
cmake --build .
sudo cmake --build . --target install
export PATH=${GEOS_PREFIX}/bin:$PATH

echo GEOS_VER="geos-3.12.0" >> $SFVARS
echo "GEOS_PREFIX=${INSTALL_PATH}/${GEOS_VER}" >> $SFVARS
echo PATH="$PATH" >> $SFVARS

#############################################################
### gdal https://gdal.org
#############################################################
GDAL_VER="gdal-3.7.2"
GDAL_PREFIX=${INSTALL_PATH}/${GDAL_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/gdal-3.7.2.tar.gz  && cd ${SOURCE_DIR}/gdal-*
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH="${SQLITE_PREFIX};${PROJ_PREFIX}" -DCMAKE_INSTALL_PREFIX="${GDAL_PREFIX}" ..

#cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH="${PROJ_PREFIX}" -DCMAKE_INSTALL_PREFIX="${GDAL_PREFIX}" ..
#cmake -DCMAKE_PREFIX_PATH="${PROJ_PREFIX}" -DCMAKE_INSTALL_PREFIX="${GDAL_PREFIX}" ..
# if sqlite rtree errors
#cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH="${PROJ_PREFIX}" -DCMAKE_INSTALL_PREFIX="${GDAL_PREFIX}" -DACCEPT_MISSING_SQLITE3_RTREE:BOOL=ON ..
# if sqlite lib errors
#cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_PREFIX_PATH="${PROJ_PREFIX}" -DSQLite3_LIBRARY=/opt/sf-package/sqlite-3.43.1/lib/libsqlite3.so -DSQLite3_INCLUDE_DIR=/opt/sf-package/sqlite-3.43.1/include -DCMAKE_INSTALL_PREFIX="${GDAL_PREFIX}" ..

cmake --build .
sudo cmake --build . --target install
export PATH=${GDAL_PREFIX}/bin:$PATH

echo GDAL_VER="gdal-3.7.2" >> $SFVARS
echo "GDAL_PREFIX=${INSTALL_PATH}/${GDAL_VER}" >> $SFVARS
echo PATH=${GDAL_PREFIX}/bin:$PATH >> $SFVARS

# -- The following RECOMMENDED packages have been found:

#  * EXPAT
#    Read and write XML formats
#  * PNG
#    PNG compression library (external)
#  * JPEG
#    JPEG compression library (external)
#  * SQLite3
#    Enable SQLite3 support (used by SQLite/Spatialite, GPKG, Rasterlite, MBTiles, etc.)
#  * GEOS
#    Geometry Engine - Open Source (GDAL core dependency)


#############################################################
### sf https://github.com/r-spatial/sf
#############################################################
export LD_LIBRARY_PATH="${GEOS_PREFIX}/lib64:${PROJ_PREFIX}/lib64:${GDAL_PREFIX}/lib64:${SQLITE_PREFIX}/lib:$LD_LIBRARY_PATH"

sudo cat > /opt/R/4.0.2/lib/R/etc/Rprofile.site <<EOF

# For gdal, geos and proj to work we prefix PKG_CONFIG_PATH and PATH

temp_pkg_path<-Sys.getenv("PKG_CONFIG_PATH")
# new_pkg_path<-"/usr/gdal34/lib/pkgconfig:/usr/geos311/lib64/pkgconfig:/usr/proj81/lib/pkgconfig"
new_pkg_path<-"/opt/sf-package/sqlite-3.43.1/lib/pkgconfig:/opt/sf-package/proj-9.3.0/lib64/pkgconfig:/opt/sf-package/gdal-3.7.2/lib64/pkgconfig:/opt/sf-package/geos-3.12.0/lib64/pkgconfig"

if (is.na(temp_pkg_path) || temp_pkg_path != '') {
  Sys.setenv(PKG_CONFIG_PATH=paste0(new_pkg_path,":",temp_pkg_path))
} else {
  Sys.setenv(PKG_CONFIG_PATH=new_pkg_path)
}

temp_path<-Sys.getenv("PATH")
#new_path<-"/usr/gdal34/bin:/usr/geos311/bin:/usr/proj81/bin"
new_path<-"/opt/sf-package/sqlite-3.43.1/bin:/opt/sf-package/proj-9.3.0/bin:/opt/sf-package/gdal-3.7.2/bin:/opt/sf-package/geos-3.12.0/bin"


if (is.na(temp_path) || temp_path != '') {
  Sys.setenv(PATH=paste0(new_path,":",temp_path))
} else {
  Sys.setenv(PATH=new_path)
}

EOF

# now this works
install.packages("sf", configure.args = c("--with-proj-lib=/opt/sf-package/proj-9.3.0/lib64/","--with-sqlite3-lib=/opt/sf-package/sqlite-3.43.1/lib/"))

#but this still doesn't with the error below!
install.packages("sf")

# configure: GDAL: 3.7.2
# configure: pkg-config proj exists, will use it
# configure: using proj.h.
# configure: PROJ: 9.3.0
# checking PROJ: checking whether PROJ and sqlite3 are available for linking:... no
# configure: error: libproj or sqlite3 not found in standard or given locations.
# ERROR: configuration failed for package ‘sf’

# SySys.getenv("PKG_CONFIG_PATH")
# [1] "/opt/sf-package/sqlite-3.43.1/lib/pkgconfig:/opt/sf-package/proj-9.3.0/lib64/pkgconfig:/opt/sf-package/gdal-3.7.2/lib64/pkgconfig:/opt/sf-package/geos-3.12.0/lib64/pkgconfig"

# > Sys.getenv("LD_LIBRARY_PATH")
# [1] "/opt/R/4.0.2/lib/R/lib:/usr/local/lib:/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.372.b07-1.el7_9.x86_64/jre/lib/amd64/server:/opt/sf-package/geos-3.12.0/lib64:/opt/sf-package/proj-9.3.0/lib64:/opt/sf-package/gdal-3.7.2/lib64:/opt/sf-package/sqlite-3.43.1/lib:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:/opt/rh/devtoolset-7/root/usr/lib64/dyninst:/opt/rh/devtoolset-7/root/usr/lib/dyninst:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib"

# /opt/sf-package/proj-9.3.0/lib64:
# total 4724
# drwxr-xr-x. 4 root root     102 Oct 17 17:59 .
# drwxr-xr-x. 6 root root      58 Oct 17 17:59 ..
# drwxr-xr-x. 4 root root      31 Oct 17 17:59 cmake
# lrwxrwxrwx. 1 root root      13 Oct 17 17:59 libproj.so -> libproj.so.25
# lrwxrwxrwx. 1 root root      19 Oct 17 17:59 libproj.so.25 -> libproj.so.25.9.3.0
# -rwxr-xr-x. 1 root root 4835432 Oct 17 17:46 libproj.so.25.9.3.0
# drwxr-xr-x. 2 root root      21 Oct 17 17:59 pkgconfig

# /opt/sf-package/sqlite-3.43.1/lib:
# total 20844
# drwxr-xr-x. 3 root root      135 Oct 17 17:39 .
# drwxr-xr-x. 6 root root       56 Oct 17 17:39 ..
# -rw-r--r--. 1 root root 15138750 Oct 17 17:39 libsqlite3.a
# -rwxr-xr-x. 1 root root     1001 Oct 17 17:39 libsqlite3.la
# lrwxrwxrwx. 1 root root       19 Oct 17 17:39 libsqlite3.so -> libsqlite3.so.0.8.6
# lrwxrwxrwx. 1 root root       19 Oct 17 17:39 libsqlite3.so.0 -> libsqlite3.so.0.8.6
# -rwxr-xr-x. 1 root root  6198792 Oct 17 17:39 libsqlite3.so.0.8.6
# drwxr-xr-x. 2 root root       24 Oct 17 17:39 pkgconfig

# /opt/sf-package/proj-9.3.0/lib64/pkgconfig/:
# total 4
# drwxr-xr-x. 2 root root  21 Oct 17 17:59 .
# drwxr-xr-x. 4 root root 102 Oct 17 17:59 ..
# -rw-r--r--. 1 root root 370 Oct 17 17:41 proj.pc

# /opt/sf-package/sqlite-3.43.1/lib/pkgconfig/:
# total 4
# drwxr-xr-x. 2 root root  24 Oct 17 17:39 .
# drwxr-xr-x. 3 root root 135 Oct 17 17:39 ..
# -rw-r--r--. 1 root root 305 Oct 17 17:39 sqlite3.pc

# to resolve this should not be needed with the pkg config in Rprofile.site
sudo ln -s /opt/sf-package/sqlite-3.43.1/lib/* /usr/local/lib/
sudo ln -s /opt/sf-package/proj-9.3.0/lib64/* /usr/local/lib64/

#now this works after setting the symlinks; but why isnt the Rprofile.site pkgconfig sufficient!!!!
install.packages("sf")
# or
/opt/R/4.0.2/bin/R -e 'install.packages("sf");library(sf)'


# #############################################################
# ### Build Notes
# #############################################################

#args <- c("--with-gdal-config=/opt/sf-package/gdal-3.7.2/bin/gdal-config","--with-geos-config=/opt/sf-package/geos-3.12.0/bin/geos-config","--with-proj-data=/opt/sf-package/proj-9.3.0/share/proj/","--with-sqlite3-lib=/opt/sf-package/sqlite-3.43.1/lib/","--with-proj-include=/opt/sf-package/proj-9.3.0/include/","--with-proj-lib=/opt/sf-package/proj-9.3.0/lib64/","--with-proj-share=/opt/sf-package/proj-9.3.0/share/")

# #install.packages("sf", configure.args = args)

# install.packages("sf", configure.args = c("--with-proj-include=/opt/sf-package/proj-9.3.0/include/","--with-proj-lib=/opt/sf-package/proj-9.3.0/lib64/","--with-sqlite3-lib=/opt/sf-package/sqlite-3.43.1/lib/"))

# ###
# #Added CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" to resolve the following error when compiling Proj
# #checking GDAL: checking whether PROJ is available fur running:... ./gdal_proj: symbol lookup error: /opt/sf-package/gdal-3.5.0/lib/libgdal.so.31: undefined symbol: sqlite3_column_table_name

# ###
# #Note the order of paths in PATH or LD_LIBRARY_PATH

# ###
# # compile time/linker flags for other software
# #
# # export PATH=${GDAL_PREFIX}:$PATH
# # export GDAL_DATA=${GDAL_PREFIX}/share/gdal
# # export CPPFLAGS="-I${PROJ_PREFIX}/include -I${GDAL_PREFIX}/include -I${SQLITE_PREFIX}/include"
# # export LDFLAGS="-L${PROJ_PREFIX}/lib64 -L${GDAL_PREFIX}/lib -L${SQLITE_PREFIX}/lib"
# # export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64:${GDAL_PREFIX}/lib64:${SQLITE_PREFIX}/lib:$LD_LIBRARY_PATH"

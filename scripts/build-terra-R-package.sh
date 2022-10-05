#############################################################
# Build and install the "terra: Spatial Data Analysis" package
# (https://rspatial.org/terra/) and dependencies from source
############################################################# 

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

#############################################################
# Build system/compiler
# CentOS Linux release 7.9.2009 (Core)
# gcc (GCC) 7.3.1 20180303 (Red Hat 7.3.1-5) (devtoolset-7)

#install newer gcc with devtoolset
if ! rpm -q centos-release-scl > /dev/null ; then
    sudo yum install centos-release-scl
fi

if ! rpm -q devtoolset-7 > /dev/null; then
    sudo yum install devtoolset-7
fi

# verify gcc 
source scl_source enable devtoolset-7
which gcc
gcc --version

#############################################################
# Begin configuration section
BUILD_ROOT=~/terra-package-build

# Set a custom installation path to INSTALL_PATH with
# e.g. INSTALL_PATH=/opt/terra-package. Leave this empty to use the
# default of /usr/local.
#
# Note: When using a custom path the versions in the respective *_VER
# variables below set the per-package installation directories and
# form the download URL's.
INSTALL_PATH=/opt/terra-package

# Software download URL's, modify these for the latest versions

## https://cmake.org/download/
CMAKE_VER="cmake-3.24.2" 
CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.24.2/${CMAKE_VER}.tar.gz"
##

## https://www.sqlite.org/download.html
SQLITE_VER="sqlite-autoconf-3390400"
SQLITE_URL="https://sqlite.org/2022/${SQLITE_VER}.tar.gz"
##

## https://proj.org/download.html
PROJ_VER="proj-9.1.0"
PROJ_URL="https://download.osgeo.org/proj/${PROJ_VER}.tar.gz"
##

## https://gdal.org/download.html#current-release
GDAL_VER="gdal-3.5.2"
GDAL_URL="https://github.com/OSGeo/gdal/releases/download/v3.5.2/${GDAL_VER}.tar.gz"
##

## https://libgeos.org/usage/download/
GEOS_VER="geos-3.11.0"
GEOS_URL="https://download.osgeo.org/geos/${GEOS_VER}.tar.bz2"
##

## https://rspatial.org/terra/
TERRA_VER="terra_1.6-7"
TERRA_URL="https://cran.r-project.org/src/contrib/Archive/terra/${TERRA_VER}.tar.gz"
##

# End configuration section
#############################################################

#create custom install directory
if test ${INSTALL_PATH}; then
    if test ! -d ${INSTALL_PATH}; then
	sudo mkdir -v ${INSTALL_PATH}
    fi
else
    echo "INSTALL_PATH is not set, using /usr/local."
fi

#check build directory is set
if test ${BUILD_ROOT}; then
    if test ! -d ${BUILD_ROOT}; then
	mkdir -v ${BUILD_ROOT}
    fi
else
    echo "BUILD_ROOT is not set"
fi

# setup and download
SOURCE_DIR=${BUILD_ROOT}/source
DOWNLOAD_DIR=${BUILD_ROOT}/download
mkdir -vp ${BUILD_ROOT} ${SOURCE_DIR} ${DOWNLOAD_DIR}

cd ${DOWNLOAD_DIR}
wget $CMAKE_URL $SQLITE_URL $PROJ_URL $GDAL_URL $GEOS_URL $TERRA_URL

# build cmake
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/cmake-*.tar.gz  && cd ${SOURCE_DIR}/cmake-*

if $CUSTOM_PATH; then
    CMAKE_PREFIX=${INSTALL_PATH}/${CMAKE_VER}
    ./bootstrap --prefix=${CMAKE_PREFIX}
    export PATH="${CMAKE_PREFIX}/bin:$PATH"
else
    ./bootstrap
fi
gmake
sudo make install

which cmake
cmake --version

# build sqlite
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/sqlite-autoconf-*.tar.gz && cd ${SOURCE_DIR}/sqlite-autoconf-*

if test ${INSTALL_PATH}; then
    SQLITE_PREFIX=${INSTALL_PATH}/${SQLITE_VER}
    CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1"  ./configure --prefix=${SQLITE_PREFIX}
    export PATH=${SQLITE_PREFIX}/bin:$PATH
else
    CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" ./configure
fi
make
sudo make install
which sqlite3
sqlite3 --version

# build proj (requires cmake/sqlite3)
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/proj-*.tar.gz  && cd ${SOURCE_DIR}/proj-*

if test ${INSTALL_PATH}; then
    PROJ_PREFIX=${INSTALL_PATH}/${PROJ_VER}
    mkdir build && cd build
    cmake -DCMAKE_PREFIX_PATH="${SQLITE_PREFIX}" -DCMAKE_INSTALL_PREFIX="${PROJ_PREFIX}" ..
    cmake --build .
    export PATH=${PROJ_PREFIX}/bin:$PATH
else
    mkdir build && cd build
    cmake ..
    cmake --build .
fi
sudo cmake --build . --target install
which proj
proj

# build gdal
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/gdal-*.tar.gz  && cd ${SOURCE_DIR}/gdal-*

if test ${INSTALL_PATH}; then
    GDAL_PREFIX=${INSTALL_PATH}/${GDAL_VER}
    ./configure --prefix="${GDAL_PREFIX}" --with-proj="${PROJ_PREFIX}"
else
    ./configure --with-proj="${PROJ_PREFIX}"
fi 
make
sudo make install

# build geos
tar -C ${SOURCE_DIR} -xvjf ${DOWNLOAD_DIR}/geos-*.tar.bz2  && cd ${SOURCE_DIR}/geos-*

if test ${INSTALL_PATH}; then
    GEOS_PREFIX=${INSTALL_PATH}/${GEOS_VER}
    ./configure --prefix="${GEOS_PREFIX}"
else
    ./configure
fi 
make
sudo make install

#############################################################
# install terra
#############################################################

#set to your R q
R_SHELL="/opt/R/4.0.2/bin/R"

if test ${INSTALL_PATH}; then
    echo "# install within an R sessions"
    echo "install.packages(\"terra\", configure.args=c(\"--with-gdal-config=${GDAL_PREFIX}/bin/gdal-config\", \"--with-geos-config=${GEOS_PREFIX}/bin/geos-config\", \"--with-proj-data=${PROJ_PREFIX}/share/proj/\", \"--with-sqlite3-lib=${SQLITE_PREFIX}/lib/\", \"--with-proj-include=${PROJ_PREFIX}/include/\", \"--with-proj-lib=${PROJ_PREFIX}/lib64/\", \"--with-proj-share=${PROJ_PREFIX}/share/\"))"
    echo "# install from command line R"
    echo "${R_SHELL} CMD INSTALL configure.args=\"--with-gdal-config=${GDAL_PREFIX}/bin/gdal-config --with-geos-config=${GEOS_PREFIX}/bin/geos-config --with-proj-data=${PROJ_PREFIX}/share/proj/ --with-sqlite3-lib=${SQLITE_PREFIX}/lib/ --with-proj-include=${PROJ_PREFIX}/include/ --with-proj-lib=${PROJ_PREFIX}/lib64/ --with-proj-share=${PROJ_PREFIX}/share/\" terra_1.6-17.tar.gz"
else
    echo "# install within an R sessions"
    echo "install.packages(\"terra\", configure.args = c(\"--with-gdal-config=/usr/local/bin/gdal-config\", \"--with-geos-config=/usr/local/bin/geos-config\", \"--with-proj-data=/usr/local/share/proj/\", \"--with-sqlite3-lib=/usr/local/lib/\", \"--with-proj-include=/usr/local/include/\", \"--with-proj-lib=/usr/local/lib64/\", \"--with-proj-share=/usr/local/share/\"))"
    echo "# install from command line R"
    echo "${R_SHELL} CMD INSTALL --configure-args=\"--with-gdal-config=/usr/local/bin/gdal-config --with-geos-config=/usr/local/bin/geos-config --with-proj-data=/usr/local/share/proj/ --with-sqlite3-lib=/usr/local/lib/ --with-proj-include=/usr/local/include/ --with-proj-lib=/usr/local/lib64/ --with-proj-share=/usr/local/share/\" terra_1.6-17.tar.gz"
fi

# R > library(terra)

#############################################################
### Build Notes
#############################################################

# add CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" to resolve the error "undefined symbol: sqlite3_column_table_name"  when compiling Proj

# note the order of paths in path or LD_LIBRARY_PATH

# compile time/linker flags for other software
# export PATH=${GDAL_PREFIX}:$PATH
# export GDAL_DATA=${GDAL_PREFIX}/share/gdal
# export CPPFLAGS="-I${PROJ_PREFIX}/include -I${GDAL_PREFIX}/include -I${SQLITE_PREFIX}/include"
# export LDFLAGS="-L${PROJ_PREFIX}/lib64 -L${GDAL_PREFIX}/lib -L${SQLITE_PREFIX}/lib"
# export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64:${GDAL_PREFIX}/lib:${SQLITE_PREFIX}/lib:$LD_LIBRARY_PATH"

# working paths for /usr/local
# > Sys.getenv("LD_LIBRARY_PATH")
# [1] "/opt/R/4.0.2/lib/R/lib:/usr/local/lib:/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.322.b06-1.el7_9.x86_64/jre/lib/amd64/server:/usr/local/lib64:/usr/local/lib:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:/opt/rh/devtoolset-7/root/usr/lib64/dyninst:/opt/rh/devtoolset-7/root/usr/lib/dyninst:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib"


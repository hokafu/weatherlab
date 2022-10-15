#!/bin/bash
#############################################################
# Build and install "terra: Spatial Data Analysis"# (https://rspatial.org/terra/) and dependencies from source
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
# README
#############################################################
#
#  To use this script...
#
# * Set your compiler as needed
# * Set the options in the configuration section below
# * Make this file executable chmod +x build-terra-R-package.sh
# * Run ./build-terra-R-package.sh|tee terra-build-$(date +%Y%m%d%H%m%S).log
# * Set the PATH,LD_LIBRARY_PATH output
# * Install the terra package with example R install commands
#
####
#
# BUILD_ROOT is the directory in which the packages are downloaded and
# built e.g. BUILD_ROOT=~/terra-build. Uses ~2.6G space
#
#
# terra-build/
# ├── download
# │   ├── cmake-3.24.2.tar.gz
# │   ├── gdal-3.5.2.tar.gz
# │   ├── geos-3.11.0.tar.bz2
# │   ├── proj-9.1.0.tar.gz
# │   ├── sqlite-autoconf-3390400.tar.gz
# │   └── terra_1.6-7.tar.gz
# └── source
#     ├── build-env
#     ├── cmake-3.24.2
#     ├── gdal-3.5.2
#     ├── geos-3.11.0
#     ├── proj-9.1.0
#     └── sqlite-autoconf-3390400
#
# Leave this empty to default to /usr/local or set a custom
# installation path to INSTALL_PATH with
# e.g. INSTALL_PATH=/opt/terra-install. Uses ~763M space.
#
#
# /opt/terra-install/
# ├── cmake-3.24.2
# ├── gdal-3.5.2
# ├── geos-3.11.0
# ├── proj-9.1.0
# └── sqlite-autoconf-3390400
#
# The versions in {NAME}_VER below are used to set the directory
# names in INSTALL_PATH so determine the install PREFIX paths

#############################################################
# Build system/compiler options

if test -f /etc/redhat-release ; then

    #install newer gcc with devtoolset on rhel/centos/rocky
    
    if ! rpm -q centos-release-scl > /dev/null ; then
	sudo yum install centos-release-scl
    fi
    
    if ! rpm -q devtoolset-7 > /dev/null; then
	sudo yum install devtoolset-7
    fi
    
    # verify gcc
    if test -f /opt/rh/devtoolset-7/enable; then
	source scl_source enable devtoolset-7
    fi
fi

which gcc
gcc --version

#############################################################
# begin configuration section

#set to your R
R_SHELL="/opt/R/4.0.2/bin/R"

# build and source parent directory
BUILD_ROOT=~/terra-build

# install directory, leave unset for /usr/local
INSTALL_PATH=/home/wrf/software/terra

# Software download URL's, modify these for the latest versions

## https://cmake.org/download/
CMAKE_VER="cmake-3.24.2"
CMAKE_URL="https://github.com/Kitware/CMake/releases/download/v3.24.2/${CMAKE_VER}.tar.gz"

## https://www.sqlite.org/download.html
SQLITE_VER="sqlite-autoconf-3390400"
SQLITE_URL="https://sqlite.org/2022/${SQLITE_VER}.tar.gz"

## https://proj.org/download.html
PROJ_VER="proj-9.1.0"
PROJ_URL="https://download.osgeo.org/proj/${PROJ_VER}.tar.gz"

## https://gdal.org/download.html#current-release
GDAL_VER="gdal-3.5.2"
GDAL_URL="https://github.com/OSGeo/gdal/releases/download/v3.5.2/${GDAL_VER}.tar.gz"

## https://libgeos.org/usage/download/
GEOS_VER="geos-3.11.0"
GEOS_URL="https://download.osgeo.org/geos/${GEOS_VER}.tar.bz2"

## https://rspatial.org/terra/
TERRA_VER="terra_1.6-7"
TERRA_URL="https://cran.r-project.org/src/contrib/Archive/terra/${TERRA_VER}.tar.gz"

# end configuration section

#############################################################
# Create directories and download files
USE_SUDO=true
#create custom install directory
if test ${INSTALL_PATH}; then
    if test -w $(dirname ${INSTALL_PATH}); then
	# install dir is writable
	USE_SUDO=false
    fi
    if test ! -d ${INSTALL_PATH}; then
	if $USE_SUDO; then
	    sudo mkdir -v ${INSTALL_PATH}
	else
	    mkdir -v ${INSTALL_PATH}
	fi
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

SOURCE_DIR=${BUILD_ROOT}/source
DOWNLOAD_DIR=${BUILD_ROOT}/download
mkdir -vp ${BUILD_ROOT} ${SOURCE_DIR} ${DOWNLOAD_DIR}

cd ${DOWNLOAD_DIR}
wget $CMAKE_URL $SQLITE_URL $PROJ_URL $GDAL_URL $GEOS_URL $TERRA_URL

#############################################################
# software compilation section

# build cmake
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/cmake-*.tar.gz  && cd ${SOURCE_DIR}/cmake-*

if test ${INSTALL_PATH}; then
    CMAKE_PREFIX=${INSTALL_PATH}/${CMAKE_VER}
    echo "Set ${CMAKE_PREFIX}"
    sleep 5
    ./bootstrap --prefix=${CMAKE_PREFIX}
    export PATH="${CMAKE_PREFIX}/bin:$PATH"
else
    ./bootstrap
fi
gmake

if $USE_SUDO; then
    sudo make install
else
    make install
fi


which cmake
cmake --version

# build sqlite
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/sqlite-autoconf-*.tar.gz && cd ${SOURCE_DIR}/sqlite-autoconf-*

if test ${INSTALL_PATH}; then
    SQLITE_PREFIX=${INSTALL_PATH}/${SQLITE_VER}
    echo "Set ${SQLITE_PREFIX}"
    sleep 5
    CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" ./configure --prefix=${SQLITE_PREFIX}
    export PATH=${SQLITE_PREFIX}/bin:$PATH
else
    CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" ./configure
fi
make
if $USE_SUDO; then
    sudo make install
else
    make install
fi
which sqlite3
sqlite3 --version

# build proj (requires cmake/sqlite3)
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/proj-*.tar.gz  && cd ${SOURCE_DIR}/proj-*

if test ${INSTALL_PATH}; then
    PROJ_PREFIX=${INSTALL_PATH}/${PROJ_VER}
    echo "Set ${PROJ_PREFIX}"
    sleep 5
    mkdir build && cd build
    cmake -DCMAKE_PREFIX_PATH="${SQLITE_PREFIX}" -DCMAKE_INSTALL_PREFIX="${PROJ_PREFIX}" ..
    cmake --build .
    export PATH=${PROJ_PREFIX}/bin:$PATH
else
    mkdir build && cd build
    cmake ..
    cmake --build .
fi

if $USE_SUDO; then
    sudo cmake --build . --target install
else
    cmake --build . --target install
fi

which proj
proj

# gdal need this to find proj
export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64":$LD_LIBRARY_PATH

# build gdal
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/gdal-*.tar.gz  && cd ${SOURCE_DIR}/gdal-*

if test ${INSTALL_PATH}; then
    GDAL_PREFIX=${INSTALL_PATH}/${GDAL_VER}
    echo "Set ${GDAL_PREFIX}"
    sleep 5
    ./configure --prefix="${GDAL_PREFIX}" --with-proj="${PROJ_PREFIX}"
else
    ./configure --with-proj="${PROJ_PREFIX}"
fi
make
if $USE_SUDO; then
sudo make install
else
make install
fi

# build geos
tar -C ${SOURCE_DIR} -xvjf ${DOWNLOAD_DIR}/geos-*.tar.bz2  && cd ${SOURCE_DIR}/geos-*

if test ${INSTALL_PATH}; then
    GEOS_PREFIX=${INSTALL_PATH}/${GEOS_VER}
    echo "Set ${GEOS_PREFIX}"
    sleep 5
    ./configure --prefix="${GEOS_PREFIX}"
else
    ./configure
fi
make
if $USE_SUDO; then
sudo make install
else
make install
fi

# extract terra to source directory
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/terra_*.tar.gz

#############################################################
# install terra
#############################################################

if test ${INSTALL_PATH}; then
    # compile time/linker flags for other software (terra)
    # Unless INSTALL_PATH is /usr/local, these need to be exported prior
    # to running R or R CMD INSTALL
    echo
    #PATH - required!
    echo "export PATH=${GDAL_PREFIX}/bin/:${GEOS_PREFIX}/bin:${SQLITE_PREFIX}/bin:${PROJ_PREFIX}/bin:\$PATH"
    #LD_LIBRARY_PATH - required!
    echo "export LD_LIBRARY_PATH=${PROJ_PREFIX}/lib64:${GDAL_PREFIX}/lib:${GEOS_PREFIX}/lib64:${SQLITE_PREFIX}/lib:\$LD_LIBRARY_PATH"
    #LDFLAGS - required!
    echo "export LDFLAGS=\"-L${PROJ_PREFIX}/lib64 -lproj -L${SQLITE_PREFIX}/lib -lsqlite3\""
    #CPPFLAGS - required!
    echo "export CPPFLAGS=\"-I${PROJ_PREFIX}/include -I${SQLITE_PREFIX}/include\""
    echo
    echo "# install within an R session"
    echo "install.packages(\"terra\", configure.args=c(\"--with-gdal-config=${GDAL_PREFIX}/bin/gdal-config\", \"--with-geos-config=${GEOS_PREFIX}/bin/geos-config\", \"--with-proj-data=${PROJ_PREFIX}/share/proj\", \"--with-sqlite3-lib=${SQLITE_PREFIX}/lib\", \"--with-proj-include=${PROJ_PREFIX}/include\", \"--with-proj-lib=${PROJ_PREFIX}/lib64\", \"--with-proj-share=${PROJ_PREFIX}/share\"))"
    echo "# install from command line R"
    echo "${R_SHELL} CMD INSTALL --configure-args=\"--with-gdal-config=${GDAL_PREFIX}/bin/gdal-config --with-geos-config=${GEOS_PREFIX}/bin/geos-config --with-proj-data=${PROJ_PREFIX}/share/proj --with-sqlite3-lib=${SQLITE_PREFIX}/lib --with-proj-include=${PROJ_PREFIX}/include --with-proj-lib=${PROJ_PREFIX}/lib64 --with-proj-share=${PROJ_PREFIX}/share\" terra_1.6-17.tar.gz"
else
    echo "# install within an R sessions"
    echo "install.packages(\"terra\", configure.args = c(\"--with-gdal-config=/usr/local/bin/gdal-config\", \"--with-geos-config=/usr/local/bin/geos-config\", \"--with-proj-data=/usr/local/share/proj\", \"--with-sqlite3-lib=/usr/local/lib\", \"--with-proj-include=/usr/local/include\", \"--with-proj-lib=/usr/local/lib64\", \"--with-proj-share=/usr/local/share\"))"
    echo "# install from command line R"
    echo "${R_SHELL} CMD INSTALL --configure-args=\"--with-gdal-config=/usr/local/bin/gdal-config --with-geos1-config=/usr/local/bin/geos-config --with-proj-data=/usr/local/share/proj --with-sqlite3-lib=/usr/local/lib --with-proj-include=/usr/local/include --with-proj-lib=/usr/local/lib64 --with-proj-share=/usr/local/share\" terra_1.6-17.tar.gz"

fi

#dump the vars and exit
export -p > ${SOURCE_DIR}/build-env
exit 1

#############################################################
### Build Notes
#############################################################
# add CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" to resolve the error "undefined symbol: sqlite3_column_table_name"  when compiling Proj

# note the order of paths in path or LD_LIBRARY_PATH

# compile time/linker flags for other software
# export PATH=${GDAL_PREFIX}:$PATH

# working paths for /usr/local install
# > Sys.getenv("LD_LIBRARY_PATH")
# [1] "/opt/R/4.0.2/lib/R/lib:/usr/local/lib:/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.322.b06-1.el7_9.x86_64/jre/lib/amd64/server:/usr/local/lib64:/usr/local/lib:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:/opt/rh/devtoolset-7/root/usr/lib64/dyninst:/opt/rh/devtoolset-7/root/usr/lib/dyninst:/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib"

# configure: Package CPP flags:  -I/opt/terra-install/proj-9.1.0/include/ -DHAVE_PROJ_H -I/opt/terra-install/gdal-3.5.2/include -I/opt/terra-install/geos-3.11.0/include
# configure: Package LIBS: -L/opt/terra-install/proj-9.1.0/lib64/  -lproj  -L/opt/terra-install/gdal-3.5.2/lib -lgdal -L/opt/terra-install/geos-3.11.0/lib64 -lgeos_c

#############################################################
### troubleshooting errors

# Error:

# [Connect] 2022/10/07 22:07:38.166973147 checking for gdal-config... no
# [Connect] 2022/10/07 22:07:38.166973468 no
# [Connect] 2022/10/07 22:07:38.166975883 configure: error: gdal-config not found or not executable.
# [Connect] 2022/10/07 22:07:38.166976283 ERROR: configuration failed for package ‘terra’

# Resolution:

# Ensure the path to gdal-config is in PATH

# Error:

# [Connect] 2022/10/07 22:18:35.696867688 checking GDAL: checking whether PROJ is available fur running:... ./gdal_proj: error while loading shared libraries: libgdal.so.31: cannot open shared object file: No such file or directory

# Resolution:

# add gdal lib path to LD_LIBRARY_PATH

# Error:

# [Connect] 2022/10/07 22:24:17.346243815 checking GDAL: checking whether PROJ is available fur running:... ./gdal_proj: error while loading shared libraries: libproj.so.25: cannot open shared object file: No such file or directory

# Resolution:

# add proj lib path to LD_LIBRARY_PATH


# Error:

# [Connect] 2022/10/07 22:34:50.488372359 checking for proj_api.h... no
# [Connect] 2022/10/07 22:34:50.488375004 configure: error: proj_api.h not found in standard or given locations.
# [Connect] 2022/10/07 22:34:50.488375385 ERROR: configuration failed for package ‘terra’
# [Connect] 2022/10/07 22:34:50.488381907 * removing ‘/opt/rstudio-connect/mnt/app/packrat/lib/x86_64-pc-linux-gnu/4.0.2/terra’

# Resolution:

# Add proj header location to the CPPFLAGS export CPPFLAGS="-I/opt/terra-install/proj-9.1.0/include"

# Error:

# [Connect] 2022/10/07 22:42:16.171219101 checking PROJ: checking whether PROJ and sqlite3 are available for linking:... no
# [Connect] 2022/10/07 22:42:16.171221235 configure: error: libproj or sqlite3 not found in standard or given locations.
# [Connect] 2022/10/07 22:42:16.171221565 ERROR: configuration failed for package ‘terra’

# Resolution:

# ?
# add proj to LD_LIBRARY_PATH LDFLAGS
# or
# add sqlite3 to PATH
# symlink libs to /usr/local
# ln -s  /opt/terra/proj-9.1.0/lib64/* /usr/local/lib64/
# ln -s  /opt/terra/proj-9.1.0/include/* /usr/local/include/

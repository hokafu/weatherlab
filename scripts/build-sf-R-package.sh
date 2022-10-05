#
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

#install newer gcc with devtoolset
if ! rpm -q centos-release-scl > /dev/null ; then
    sudo yum install centos-release-scl
fi

if ! rpm -q devtoolset-7 > /dev/null; then
    sudo yum install devtoolset-7
fi

# verify gcc 
source scl_source enable devtoolset-7
gcc --version

# sets the build dir 
BUILD_ROOT=~/sf-package-build 

SOURCE_DIR=${BUILD_ROOT}/source
DOWNLOAD_DIR=${BUILD_ROOT}/download
mkdir -vp ${BUILD_ROOT} ${SOURCE_DIR} ${DOWNLOAD_DIR} ${INSTALL_PATH}

# sets the install path
INSTALL_PATH=/opt/sf-package

sudo mkdir -v ${INSTALL_PATH}
cd ${DOWNLOAD_DIR}

#############################################################
### Downloads
#############################################################
wget https://github.com/Kitware/CMake/releases/download/v3.23.2/cmake-3.23.2.tar.gz
wget https://github.com/OSGeo/gdal/releases/download/v3.5.0/gdal-3.5.0.tar.gz
wget https://download.osgeo.org/proj/proj-9.0.0.tar.gz
# wget https://download.osgeo.org/proj/proj-data-1.9.tar.gz # local proj data
wget https://sqlite.org/2022/sqlite-autoconf-3380500.tar.gz
wget https://cran.r-project.org/src/contrib/sf_1.0-7.tar.gz

#############################################################
### cmake https://cmake.org/
#############################################################
CMAKE_VER="cmake-3.23.2"
CMAKE_PREFIX=${INSTALL_PATH}/${CMAKE_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/cmake-3.23.2.tar.gz  && cd ${SOURCE_DIR}/cmake-*
./bootstrap --prefix=${CMAKE_PREFIX}
gmake
sudo make install
export PATH="${CMAKE_PREFIX}/bin:$PATH"
cmake --version

#############################################################
### sqlite https://sqlite.org/index.html
#############################################################
SQLITE_VER="sqlite-3.38.5"
SQLITE_PREFIX=${INSTALL_PATH}/${SQLITE_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/sqlite-autoconf-3380500.tar.gz  && cd ${SOURCE_DIR}/sqlite-autoconf-*
CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1"
./configure --prefix=${SQLITE_PREFIX}
make
sudo make install
export PATH=${SQLITE_PREFIX}/bin:$PATH
sqlite3 --version

#############################################################
### proj (requires cmake/sqlite3) https://proj.org/index.html
#############################################################
PROJ_VER="proj-9.0.0"
PROJ_PREFIX=${INSTALL_PATH}/${PROJ_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/proj-9.0.0.tar.gz  && cd ${SOURCE_DIR}/proj-*
mkdir build && cd build
cmake -DCMAKE_PREFIX_PATH="${SQLITE_PREFIX}" -DCMAKE_INSTALL_PREFIX="${PROJ_PREFIX}" ..
cmake --build .
sudo cmake --build . --target install
export PATH=${PROJ_PREFIX}/bin:$PATH
proj --version

#############################################################
### gdal https://gdal.org
#############################################################
GDAL_VER="gdal-3.5.0"
GDAL_PREFIX=${INSTALL_PATH}/${GDAL_VER}
tar -C ${SOURCE_DIR} -xvzf ${DOWNLOAD_DIR}/gdal-3.5.0.tar.gz  && cd ${SOURCE_DIR}/gdal-*
./configure --prefix=
./configure --prefix="${GDAL_PREFIX}" --with-proj="${PROJ_PREFIX}"
make
sudo make install

#############################################################
### sf https://github.com/r-spatial/sf
#############################################################
# /opt/R/4.0.2/bin/R
# R > install.packages("sf", configure.args = c("--with-gdal-config=/opt/sf-package/gdal-3.5.0/bin/gdal-config", "--with-proj-data=/opt/sf-package/proj-9.0.0/share/proj/", "--with-sqlite3-lib=/opt/sf-package/sqlite-3.38.5/lib/", "--with-proj-include=/opt/sf-package/proj-9.0.0/include/", "--with-proj-lib=/opt/sf-package/proj-9.0.0/lib64/", "--with-proj-share=/opt/sf-package/proj-9.0.0/share/"))
# R > library(sf)
# Linking to GEOS 3.4.2, GDAL 3.5.0, PROJ 9.0.0; sf_use_s2() is TRUE

#############################################################
### Build Notes
#############################################################

### 
#Added CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" to resolve the following error when compiling Proj
#checking GDAL: checking whether PROJ is available fur running:... ./gdal_proj: symbol lookup error: /opt/sf-package/gdal-3.5.0/lib/libgdal.so.31: undefined symbol: sqlite3_column_table_name

### 
#Note the order of paths in PATH or LD_LIBRARY_PATH

### 
# compile time/linker flags for other software
#
# export PATH=${GDAL_PREFIX}:$PATH
# export GDAL_DATA=${GDAL_PREFIX}/share/gdal
# export CPPFLAGS="-I${PROJ_PREFIX}/include -I${GDAL_PREFIX}/include -I${SQLITE_PREFIX}/include"
# export LDFLAGS="-L${PROJ_PREFIX}/lib64 -L${GDAL_PREFIX}/lib -L${SQLITE_PREFIX}/lib"
# export LD_LIBRARY_PATH="${PROJ_PREFIX}/lib64:${GDAL_PREFIX}/lib:${SQLITE_PREFIX}/lib:$LD_LIBRARY_PATH"
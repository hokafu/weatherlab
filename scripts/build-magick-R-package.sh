# Notes for building the magick R package with HEIC image support

# create a working directory
mkdir magick-build
cd magick-build

The install prefix path is /opt/software, change to suit your path.

#install dependencies
sudo dnf install nasm ninja-build

# Build x265
git clone https://bitbucket.org/multicoreware/x265_git.git x265
cd x265/build/linux/
./make-Makefiles # update the prefix path
make
sudo make install
/opt/software/x265/bin/x265 --version
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/software/x265/lib/pkgconfig

# Build libde265
git clone https://github.com/strukturag/libde265.git
cd libde265/
./autogen.sh
./configure --prefix /opt/software/libde265 --disable-sherlock265
make
sudo make install
pkgconf --libs /opt/software/libde265/lib/pkgconfig/libde265.pc
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/software/libde265/lib/pkgconfig
export LD_LIBRARY_PATH=/opt/software/x265/lib:/opt/software/libde265/lib

# Build libheif
# remove the existing RPM's to avoid cmake conflicts!
dnf remove --noautoremove  libheif  libheif libheif

git clone https://github.com/strukturag/libheif.git
cd libheif
mkdir build && cd build
cmake --preset=release-noplugins -DCMAKE_INSTALL_PREFIX="/opt/software/libheif/" ..
cmake --build .
sudo cmake --build . --target install

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/software/libheif/lib/pkgconfig
export LD_LIBRARY_PATH=/opt/software/x265/lib:/opt/software/libde265/lib:/opt/software/libheif/lib64/

# Build ImageMagick
wget https://imagemagick.org/archive/ImageMagick.tar.gz
tar xvzf ImageMagick.tar.gz
cd ImageMagick-*
./configure --prefix=/opt/software/ImageMagick-7.1.2-7 --with-fftw=yes --with-rsvg=yes
egrep CONFIGURE_ARGS config.log # confirm the correct libheif is used
make
sudo make install

#reinstall OS libheif
dnf install libheif  libheif libheif

# Notes
You'll need to include the paths to the shared libraries in your R LD_LIBRARY_PATH (e.g.,  /opt/software/ImageMagick-7.1.2-7/lib:/opt/software/libde265/lib:/opt/software/x265/lib:/opt/software/libheif/lib64/").

Then in R session ...

> Sys.getenv("LD_LIBRARY_PATH")
[1] "/opt/R/4.4.3/lib/R/lib:/usr/local/lib:/usr/lib/jvm/jre-11-openjdk/lib/server:/opt/software/ImageMagick-7.1.2-7/lib::/opt/software/ImageMagick-7.1.2-7/lib:/opt/software/libde265/lib:/opt/software/x265/lib:/opt/software/libheif/lib64/"
> options(repos = c(CRAN = "https://p3m.dev/cran/latest"))
> install.packages("magick", qu)
quiet=           quakes           quarters         quarters.POSIXt  quartz.options   quartzFont       quasi            quasipoisson     qunif            
quade.test       quantile         quarters.Date    quartz           quartz.save      quartzFonts      quasibinomial    quit             quote            
> install.packages("magick", qui)
quiet=  quit    
> install.packages("magick", quiet=TRUE)
> library(magick)
Linking to ImageMagick 7.1.2.8
Enabled features: cairo, fontconfig, freetype, fftw, heic, lcms, raw, rsvg, x11
Disabled features: ghostscript, pango, webp
> magick::image_read("~/Downloads/soundboard.heic")
  format width height colorspace matte filesize density
1   HEIC  3000   4000       sRGB FALSE  1221347 +72x+72
> 

 


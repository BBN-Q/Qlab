BBN APS - libx6-cpp

This directory contains initial driver code to support the use of an Innovative Integration
X6-1000 card as a APS unit. 

http://www.innovative-dsp.com/products.php?product=X6-1000M

The driver is currently completely seperate from the libaps driver and is based on the
libaps driver forked on 2/11/2013. 

Requirements:

cmake: Cmake build tool version 2.8 or higher (http://www.cmake.org/)
gcc: g++ 4.7.1 or higher, currently building using gcc supplied with mingw
malibu: Innovative Integration Malibu library
        http://www.innovative-dsp.com/products.php?product=Malibu

Building Code (on windows using MSYS):

mkdir build
cd build
cmake -G "MSYS Makefiles" ../src/
make
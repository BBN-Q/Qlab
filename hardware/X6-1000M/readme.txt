X6-1000M

This directory contains initial driver code to support the use of an Innovative Integration
X6-1000 card as a data acquisition card.

http://www.innovative-dsp.com/products.php?product=X6-1000M

Based upon Brian Donovan's libx6 driver for the X6-hosted BBNAPS.

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
BBN APS - libaps2-cpp

This directory contains initial driver code to support the use of the ethernet controlled APS2

The driver is currently completely seperate from the libaps driver and is based on the
libaps driver forked on 4/4/2013. 

Requirements:

cmake: Cmake build tool version 2.8 or higher (http://www.cmake.org/)
gcc: g++ 4.7.1 or higher, currently building using gcc supplied with mingw

Building Code (on windows using MSYS):

mkdir build
cd build
cmake -G "MSYS Makefiles" ../src/
make

Winpcap Details:
Winpcap driver downloaded on 4/4/2013
Not compatible with Mingw-w64
Had to rebuild from source using notes from:
http://mathieu.carbou.free.fr/wiki/?title=Winpcap_/_Libpcap#Installing_Winpcap_in_MinGW
http://www.mail-archive.com/winpcap-users@winpcap.org/msg00750.html

Downloaded winpcap 4.1.3 source see winpcap_4_1_4_mingw_w64.patch
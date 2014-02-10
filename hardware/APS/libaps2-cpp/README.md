# BBN APSv2 Driver

This directory contains C++ driver code to support the use of the ethernet controlled APS2

The driver is currently completely seperate from the libaps driver and is based on the
libaps driver forked on 4/4/2013. 

## Dependencies:

* cmake: Cmake build tool version 2.8 or higher (http://www.cmake.org/)
* gcc: g++ 4.7.1 or higher, currently building using gcc supplied with mingw
* hdf5 : currently built against ????
* [asio](http://think-async.com/) : We use the standalone asio package. 


## Building Code 

### Windows using MSYS and mingw-builds:

```
mkdir build
cd build
cmake -DHDF5_INCLUDE_DIR:STRING=/path/to/hdf5/inculde -DASIO_INCLUDE_DIR:STRING=/path/to/asio -G "MSYS Makefiles" ../src/
make
```

## Firewall

We are using UDP packets on port 47950 so if a firewall is in place a rule must be added to allow these packets through. 
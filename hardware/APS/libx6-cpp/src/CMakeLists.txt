# build using
# mkdir build
# cd build
# cmake -G "MSSYS Makefiles" ../CMake/
# make

PROJECT( libx6 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

SET (  INNOVATIVEPATH "C:\\Apps\\Innovative" )
SET (  MALIBUPATH   ${INNOVATIVEPATH}/Malibu )

INCLUDE_DIRECTORIES(${MALIBUPATH})
INCLUDE_DIRECTORIES("c:/Apps/msys/local/hdf5/include/cpp")
INCLUDE_DIRECTORIES("c:/Apps/msys/local/hdf5/include")

ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-DGCC")
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-std=c++11")

SET ( DLL_SRC 


	./APS/libaps.cpp
	./APS/libaps.h
	./APS/FPGA.cpp
	./APS/FPGA.h
	./APS/Channel.cpp
	./APS/Channel.h
	./APS/APS.cpp
	./APS/APS.h
	./APS/APSRack.cpp
	./APS/APSRack.h
	./APS/headings.h

	./innovative/ApplicationIO.cpp
	./innovative/ApplicationIO.h
	./innovative/ModuleIo.cpp 
	./innovative/ModuleIo.h
)

SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

ADD_LIBRARY( libx6 ${DLL_SRC} )





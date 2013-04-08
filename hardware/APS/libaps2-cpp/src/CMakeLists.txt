# build using
# mkdir build
# cd build
# cmake -G "MSSYS Makefiles" ../CMake/
# make

PROJECT( libaps2 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

SET (  WINPCAPPATH "C:\\Apps\\winpcap" )

# define WIN32 for winpcap
if (WIN32)
	add_definitions( -DWIN32 )
endif(WIN32)

FIND_PACKAGE(HDF5)
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR}/cpp )


INCLUDE_DIRECTORIES(${WINPCAPPATH}/Include)
INCLUDE_DIRECTORIES("./APS/")

LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\Projects\\MQCO\\Qlab\\hardware\\APS\\libaps2-cpp\\lib\\winpcap\\")

ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-DGCC")
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-std=c++11")

SET ( DLL_SRC 
	./APS/libaps.cpp
	./APS/FPGA.cpp
	./APS/Channel.cpp
	./APS/APS.cpp
	./APS/APSRack.cpp
	./APS/LLBank.cpp
	./APS/EthernetControl.cpp
)


SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

ADD_LIBRARY( aps2 SHARED ${DLL_SRC} )
ADD_EXECUTABLE(test 
	./test/main.cpp
	./APS/EthernetControl.cpp )

 TARGET_LINK_LIBRARIES(test wpcap Packet ws2_32 iphlpapi)

TARGET_LINK_LIBRARIES(aps2 
	
	hdf5_cpp
	hdf5

	wpcap Packet
	ws2_32
	iphlpapi    # for GetAdaptersInfo
)








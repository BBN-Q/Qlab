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
if (HDF5_FOUND)
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR}/cpp )
else()
INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\hdf5\\include")
INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\hdf5\\include\\cpp")
LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\MinGW\\msys\\1.0\\local\\hdf5\\lib")  
endif()


INCLUDE_DIRECTORIES(${WINPCAPPATH}/Include)
INCLUDE_DIRECTORIES("./APS/")

If(CMAKE_SIZEOF_VOID_P EQUAL 8)
	LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\Projects\\MQCO\\Qlab\\hardware\\APS\\libaps2-cpp\\lib\\winpcap\\x64\\")    
 else()
     LINK_DIRECTORIES( ${LINK_DIRECTORIES} "Y:\\APS\\libaps2-cpp\\lib\\winpcap\\x86\\")  
 endif()


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
	./APS/APS2.cpp
)


SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

ADD_LIBRARY( aps2 SHARED ${DLL_SRC} )

ADD_EXECUTABLE(test
	./test/main.cpp
)

ADD_EXECUTABLE(echo
	./test/echo.cpp
	./APS/EthernetControl.cpp 
	./APS/DummyAPS.cpp
	./APS/APS2.cpp
)

TARGET_LINK_LIBRARIES(echo 
	wpcap Packet
	ws2_32
	iphlpapi 
)

set_target_properties(echo PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

#ADD_EXECUTABLE(echo32
#	./test/echo.cpp
#	./APS/EthernetControl.cpp 
#	./APS/DummyAPS.cpp
#)

#TARGET_LINK_LIBRARIES(echo32
#	wpcap Packet
#	ws2_32
#	iphlpapi 
#)

#set_target_properties(echo32 PROPERTIES COMPILE_FLAGS "-m32" LINK_FLAGS "-m32")
#set_target_properties(echo32 PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")


TARGET_LINK_LIBRARIES(test aps2)

TARGET_LINK_LIBRARIES(aps2 
	
	hdf5_cpp
	hdf5

	wpcap Packet
	ws2_32
	iphlpapi    # for GetAdaptersInfo
)








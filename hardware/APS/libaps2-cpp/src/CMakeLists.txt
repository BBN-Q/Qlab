# build using
# mkdir build
# cd build
# cmake -G "MSSYS Makefiles" ../CMake/  # -For Windows
# 
# make

PROJECT( libaps2 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)


# define WIN32 for winpcap
if (WIN32)
	SET (  WINPCAPPATH "C:\\Apps\\winpcap" )
	INCLUDE_DIRECTORIES(${WINPCAPPATH}/Include)
	add_definitions( -DWIN32 )
endif(WIN32)


#look for hdf5 and otherwise hack in mingw64 built one
FIND_PACKAGE(HDF5)
if (HDF5_FOUND)
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR}/cpp )
else()
INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\hdf5\\include")
INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\hdf5\\include\\cpp")
LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\MinGW\\msys\\1.0\\local\\hdf5\\lib")  
endif()


#Grab all the header files in the src directory including concol.h
INCLUDE_DIRECTORIES("./APS/")

#ASIO files
INCLUDE_DIRECTORIES("../asio/")
ADD_DEFINITIONS(-DASIO_STANDALONE)

#Check for 32bit or 64 bit platform and link against the appropriate winpcap
if(WIN32)
if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	LINK_DIRECTORIES( ${LINK_DIRECTORIES} "..\\lib\\winpcap\\x64\\")    
 else()
     LINK_DIRECTORIES( ${LINK_DIRECTORIES} "..\\lib\\winpcap\\x86\\")  
endif()
endif(WIN32)

#Add flags for gcc and C++11
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-DGCC")
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-std=c++11")
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-Wall")

SET ( DLL_SRC 
	./APS/libaps.cpp
	./APS/Channel.cpp
	./APS/APS2.cpp
	./APS/LLBank.cpp
	./APS/APSEthernet.cpp
	./APS/MACAddr.cpp
	./APS/APSEthernetPacket.cpp
)


SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

ADD_LIBRARY( aps2 SHARED ${DLL_SRC} )

ADD_EXECUTABLE(test
	./test/main.cpp
)

#ADD_EXECUTABLE(echo
#	./test/echo.cpp
#	./APS/APSEthernet.cpp 
#	./APS/DummyAPS.cpp
#	./APS/APS2.cpp
#)

#For Windows pull in some additional libraries for network stuff
if (WIN32)
TARGET_LINK_LIBRARIES(echo 
	wpcap Packet
	ws2_32
	iphlpapi 
)
endif(WIN32)

#set_target_properties(echo PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

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
)

if (WIN32)
TARGET_LINK_LIBRARIES(aps2 
	wpcap Packet
	ws2_32
	iphlpapi    # for GetAdaptersInfo
)
else()
TARGET_LINK_LIBRARIES(aps2 
	pcap
)
endif(WIN32)







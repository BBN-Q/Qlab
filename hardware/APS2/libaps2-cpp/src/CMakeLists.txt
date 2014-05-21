# build using
# mkdir build
# cd build
# cmake -G "MSYS Makefiles" -DHDF5_INCLUDE_DIR:string=/path/to/hdf5 -DASIO_INCLUDE_DIR:string=/path/to/asio ../src/  # -For Windows
# 
# make

PROJECT( libaps2 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
SET ( CMAKE_BUILD_TYPE Debug )

#Look for hdf5 directly passed; otherwise look for system one
if(NOT DEFINED HDF5_INCLUDE_DIR)
	FIND_PACKAGE(HDF5)
	if (NOT HDF5_FOUND)
		message("Unable to find HDF5 libraries.")
		return()
	endif()
endif()
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR} )
INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR}/cpp )
if(DEFINED HDF5_INCLUDE_DIR)
	LINK_DIRECTORIES( ${LINK_DIRECTORIES} ${HDF5_INCLUDE_DIR}/../lib)
endif()

#Grab all the header files in the src directory including concol.h
INCLUDE_DIRECTORIES("./APS/")

#ASIO files
if(NOT DEFINED ASIO_INCLUDE_DIR)
	message("ASIO include directory not defined.")
	return()
endif()
INCLUDE_DIRECTORIES( ${ASIO_INCLUDE_DIR} )
ADD_DEFINITIONS(-DASIO_STANDALONE)

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

ADD_EXECUTABLE(waveforms
	./test/waveforms.cpp
)

ADD_EXECUTABLE(flash
	./test/flash.cpp
)

ADD_EXECUTABLE(reset
	./test/reset.cpp
)

ADD_EXECUTABLE(program
	./test/program.cpp
)

#ADD_EXECUTABLE(echo
#	./test/echo.cpp
#	./APS/APSEthernet.cpp 
#	./APS/DummyAPS.cpp
#	./APS/APS2.cpp
#)


#set_target_properties(echo PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

#ADD_EXECUTABLE(echo32
#	./test/echo.cpp
#	./APS/EthernetControl.cpp 
#	./APS/DummyAPS.cpp
#)

#set_target_properties(echo32 PROPERTIES COMPILE_FLAGS "-m32" LINK_FLAGS "-m32")
#set_target_properties(echo32 PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

TARGET_LINK_LIBRARIES(test aps2)
TARGET_LINK_LIBRARIES(flash aps2)
TARGET_LINK_LIBRARIES(waveforms aps2)
TARGET_LINK_LIBRARIES(reset aps2)
TARGET_LINK_LIBRARIES(program aps2)

if(WIN32)
TARGET_LINK_LIBRARIES(aps2 hdf5	hdf5_cpp ws2_32)
else(WIN32)
TARGET_LINK_LIBRARIES(aps2 hdf5	hdf5_cpp)
endif(WIN32)





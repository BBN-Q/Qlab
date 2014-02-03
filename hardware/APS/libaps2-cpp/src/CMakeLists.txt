# build using
# mkdir build
# cd build
# cmake -G "MSSYS Makefiles" ../CMake/  # -For Windows
# 
# make

PROJECT( libaps2 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)


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


#set_target_properties(echo PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

#ADD_EXECUTABLE(echo32
#	./test/echo.cpp
#	./APS/EthernetControl.cpp 
#	./APS/DummyAPS.cpp
#)

#set_target_properties(echo32 PROPERTIES COMPILE_FLAGS "-m32" LINK_FLAGS "-m32")
#set_target_properties(echo32 PROPERTIES COMPILE_DEFINITIONS "DEBUGAPS")

TARGET_LINK_LIBRARIES(test aps2)

TARGET_LINK_LIBRARIES(aps2 
	hdf5_cpp
	hdf5
)







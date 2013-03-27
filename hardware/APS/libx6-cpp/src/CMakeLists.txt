# build using
# mkdir build
# cd build
# cmake -G "MSSYS Makefiles" ../CMake/
# make

PROJECT( libx6 )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

SET (  INNOVATIVEPATH "C:\\Innovative" )
SET (  MALIBUPATH   ${INNOVATIVEPATH}/Malibu )


# devel machine path may be removeed if FIND_PACKAGE HDF5 works
	INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\include\\cpp")
	INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\include")	
	LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\MinGW\\msys\\1.0\\local\\lib")

#FIND_PACKAGE(HDF5)
#INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR} )
#INCLUDE_DIRECTORIES( ${HDF5_INCLUDE_DIR}/cpp )


INCLUDE_DIRECTORIES(${MALIBUPATH})
INCLUDE_DIRECTORIES("./innovative/")
INCLUDE_DIRECTORIES("./APS/")

LINK_DIRECTORIES( ${LINK_DIRECTORIES} 
	"C:\\Innovative\\Lib\\Gcc"
)

# following links against Innovative release libraries
LINK_DIRECTORIES( ${LINK_DIRECTORIES} 
	"C:\\Innovative\\Lib\\Gcc\\Debug"
)


ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-DGCC")
ADD_DEFINITIONS(${CMAKE_CXX_FLAGS} "-std=c++11")

SET ( DLL_SRC 
	./APS/libaps.cpp
	./APS/FPGA.cpp
	./APS/Channel.cpp
	./APS/APS.cpp
	./APS/APSRack.cpp
	./APS/LLBank.cpp
	./APS/X6_1000.cpp
	./innovative/Thunker_Con.cpp	
	./innovative/CommandLine_Con.cpp	
)

#	./innovative/ApplicationIO.cpp


SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

SET_SOURCE_FILES_PROPERTIES( ${TEST_SRC} PROPERTIES LANGUAGE CXX )


ADD_LIBRARY( x6 SHARED ${DLL_SRC} )
ADD_EXECUTABLE(x6test ./test/main.cpp ${DLL_SRC})

TARGET_LINK_LIBRARIES(x6test 
	Application_Mb
	Pci_Mb
	Hardware_Mb
	Analysis_Mb
	Utility_Mb
	Os_Mb
	Ficl_Mb
	Framework_Mb 
	ipps-7.0  # in Intel IPP directory listed above
	wdapi # WinDriver library in Innovative\lib\gcc

	hdf5_cpp
	hdf5
	
	# The following libraries are supplied with Malibu
	# But not currently required
	#Framework_Win 
	#Framework_Con ##
	#Poco_Foundation_Mb ##
	#Poco_Net_Mb ##
	#Vpx_Mb  ##
)

TARGET_LINK_LIBRARIES(x6 
	Application_Mb
	Pci_Mb
	Hardware_Mb
	Analysis_Mb
	Utility_Mb
	Os_Mb
	Ficl_Mb
	
	ipps-7.0  # in Intel IPP directory listed above
	wdapi # WinDriver library in Innovative\lib\gcc

	hdf5_cpp
	hdf5
	
	# The following libraries are supplied with Malibu
	# But not currently required
	#Framework_Win 
	#Framework_Con ##
	#Poco_Foundation_Mb ##
	#Poco_Net_Mb ##
	#Vpx_Mb  ##
)






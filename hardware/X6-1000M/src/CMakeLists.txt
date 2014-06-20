# build using
# mkdir build
# cd build
# cmake -G "MSYS Makefiles" ../src/
# make

PROJECT( libx6adc )
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)
SET ( CMAKE_BUILD_TYPE Debug )

SET (  INNOVATIVEPATH "C:\\Innovative" )
SET (  MALIBUPATH   ${INNOVATIVEPATH}/Malibu )


# devel machine path may be removed if FIND_PACKAGE HDF5 works
#	INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\include\\cpp")
#	INCLUDE_DIRECTORIES("C:\\MinGW\\msys\\1.0\\local\\include")	
#	LINK_DIRECTORIES( ${LINK_DIRECTORIES} "C:\\MinGW\\msys\\1.0\\local\\lib")


INCLUDE_DIRECTORIES(${MALIBUPATH})
INCLUDE_DIRECTORIES(".")

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
	./libx6adc.cpp
	./X6.cpp
	./X6_1000.cpp
)

SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

SET_SOURCE_FILES_PROPERTIES( ${TEST_SRC} PROPERTIES LANGUAGE CXX )


ADD_LIBRARY( x6adc SHARED ${DLL_SRC} )
ADD_EXECUTABLE(x6test ../test/main.cpp )

TARGET_LINK_LIBRARIES(x6test x6adc)

TARGET_LINK_LIBRARIES(x6adc
	-Wl,--start-group
	Os_Mb
	Application_Mb
	Analysis_Mb
	Framework_Con
	Framework_Mb
	Utility_Mb
	Hardware_Mb
	Pci_Mb
	Ficl_Mb
	-Wl,--end-group
	
	wdapi # WinDriver library in Innovative\lib\gcc
	ipps-7.0  # in Intel IPP directory listed above
	
	# The following libraries are not currently required
	#Framework_Win 
	#Vpx_Mb  ##
)

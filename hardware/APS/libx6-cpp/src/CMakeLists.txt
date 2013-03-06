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
INCLUDE_DIRECTORIES("./innovative/")

LINK_DIRECTORIES( ${LINK_DIRECTORIES} 
	"C:\\Apps\\Innovative\\Lib\\Gcc"
)

# following links against Innovative release libraries
LINK_DIRECTORIES( ${LINK_DIRECTORIES} 
	"C:\\Apps\\Innovative\\Lib\\Gcc\\Release"
)

# following links against Innovative release libraries
LINK_DIRECTORIES( ${LINK_DIRECTORIES} 
	"c:/Apps/msys/local/hdf5/lib"
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

	./innovative/ModuleIo.cpp 
	./innovative/Thunker.cpp 

)

#	./innovative/ApplicationIO.cpp




SET_SOURCE_FILES_PROPERTIES( ${DLL_SRC} PROPERTIES LANGUAGE CXX )

ADD_LIBRARY( x6 SHARED ${DLL_SRC} )



TARGET_LINK_LIBRARIES(x6 
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






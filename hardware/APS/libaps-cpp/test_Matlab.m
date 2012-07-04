%Simple script to test the CPP library from Matlab
loadlibrary('libaps.dll','libaps.h');

libfunctions('libaps','-full');

calllib('libaps','Init')
calllib('libaps','connect_by_ID',0)
bitFile = 'C:\Users\qlab\Qlab Software\common\src\+deviceDrivers\@APS\mqco_aps_latest.bit';
calllib('libaps','program_FPGA',[bitFile 0], 3, 16)

calllib('libaps','disconnect')
unloadlibrary('libaps')
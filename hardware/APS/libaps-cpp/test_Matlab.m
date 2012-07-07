%Simple script to test the CPP library from Matlab
loadlibrary('libaps.dll','libaps.h');

% libfunctions('libaps','-full');

calllib('libaps','init')
calllib('libaps','connect_by_ID',0)
bitFile = 'C:\Users\qlab\Qlab Software\common\src\+deviceDrivers\@APS\mqco_aps_latest.bit';
calllib('libaps','initAPS', 0, [bitFile 0], 1)

calllib('libaps','set_sampleRate',0,0,1200,0)
calllib('libaps','set_sampleRate',0,1,1200,0)
calllib('libaps','get_sampleRate',0,1)

ramp = 1:4000;
calllib('libaps','set_waveform_int',0,0,ramp,length(ramp))

calllib('libaps','disconnect_by_ID',0)
 
unloadlibrary('libaps')
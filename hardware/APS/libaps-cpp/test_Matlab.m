%Simple script to test the CPP library from Matlab
loadlibrary('libaps.dll','libaps.h');

calllib('libaps','Init')

unloadlibrary('libaps')
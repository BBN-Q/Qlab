#!/bin/sh

repository=https://qubit.bbn.com/svn/MQCO/trunk
waveform=$repository/common/src/util/
driver=$repository/common/src/+deviceDrivers/@DacII@

svn co $waveform
svn co $driver

mkdir dacii

cp util/dacIIWaveform.m ./dacii/
cp @DacII/* ./dacii/

mv @DacII/lib/ ./dacii/ 
#  remove .svn
rm -rf ./dacii/lib/.svn

cp util/DacIIGui/* ./dacii/

rm -rf util
rm -rf \@DacII

# remove reference to experiment framework from DacII gui
sed -i 's/classdef DacII < deviceDrivers.lib.deviceDriverBase/classdef DacII < handle/g' ./dacii/dacII.m
sed -i 's/d = d@deviceDrivers.lib.deviceDriverBase/%d = d@deviceDrivers.lib.deviceDriverBase/g' ./dacii/dacII.m
# convert line endings back to windows
sed -i 's/$'"/`echo \\\r`/"  ./dacii/dacII.m       


# rebuild libdacii.dll
cd dacii/lib
make clean
make all
cd -

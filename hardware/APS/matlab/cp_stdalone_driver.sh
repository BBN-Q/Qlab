#!/bin/sh

repository=../../../
util=$repository/common/src/util/
driver=$repository/common/src/+deviceDrivers/@APS

mkdir Standalone
mkdir Standalone/aps

cp $util/APSWaveform.m ./Standalone/aps/
cp -R $driver/* ./Standalone/aps/

cp $util/APSGui/* ./Standalone/aps/

# remove reference to experiment framework from APS gui
sed -i 's/classdef APS < deviceDrivers.lib.deviceDriverBase/classdef APS < handle/g' ./Standalone/aps/APS.m
sed -i 's/d = d@deviceDrivers.lib.deviceDriverBase/%d = d@deviceDrivers.lib.deviceDriverBase/g' ./Standalone/aps/APS.m
# convert line endings back to windows
sed -i 's/$'"/`echo \\\r`/"  ./Standalone/aps/APS.m       


# rebuild libaps.dll
cd ./Standalone/aps/lib
make clean
make all
cd -

# copy patternGen

cp -R $util/@PatternGen ./Standalone/
cp $util/parseargs.m ./Standalone/
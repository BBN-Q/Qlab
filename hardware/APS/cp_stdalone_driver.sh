#!/bin/sh

repository=../../
util=$repository/common/src/util
matlabdriver=$repository/common/src/+deviceDrivers/@APS

mkdir Standalone

mkdir Standalone/libaps-cpp
cp -R libaps-cpp/build32 Standalone/libaps-cpp/
cp -R libaps-cpp/build64 Standalone/libaps-cpp/

cp -R python Standalone/

cp -R bitfiles Standalone/
cp -R examples Standalone/

mkdir Standalone/matlab
cp -R $matlabdriver Standalone/matlab/
cp -R $util/@APSPattern Standalone/matlab
cp -R $util/@PatternGen Standalone/matlab
cp -R $util/@Pulse Standalone/matlab

# fix APS_ROOT reference
sed -i "s#APS_ROOT = '../../../../hardware/APS'#APS_ROOT = '../../'#" Standalone/matlab/@APS/APS.m

cp $util/parseargs.m Standalone/matlab


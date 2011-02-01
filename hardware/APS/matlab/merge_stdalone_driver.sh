#!/bin/sh

repository=https://qisrep.bbn.com/svn/qlab/trunk
waveform=$repository/common/src/util/
driver=$repository/common/src/+deviceDrivers/@DacII@

mkdir svndir
cd svndir

svn co $waveform
svn co $driver

cd -

# copy files over
cp ./dacii/dacII.m ./svndir/@DacII/dacII.m
mv ./svndir/@DacII/dacII.m ./svndir/@DacII/DacII.m
cp ./dacii/lib/* ./svndir/@DacII/lib/
cp ./dacii/lib/include/* ./svndir/@DacII/lib/include/
cp ./dacii/{DacIIGui,guifunctions,mainwindow,msgmanager}.m ./svndir/util/DacIIGui/
cp ./dacii/dacIIwaveform.m ./svndir/util/
cp ./dacii/*.bit ./svndir/@DacII/

# convert object names to correct packages
sed -i 's/classdef dacII < handle/classdef DacII < deviceDrivers.lib.deviceDriverBase/g' ./svndir/@DacII/DacII.m
sed -i 's/%d = d@deviceDrivers.lib.deviceDriverBase/d = d@deviceDrivers.lib.deviceDriverBase/g' ./svndir/@DacII/DacII.m
# convert line endings back to windows
sed -i 's/$'"/`echo \\\r`/"  ./svndir/@DacII/DacII.m          

echo "run svn status in ./svndir/@DacII and ./svndir/util"
echo "Each directory is a seperate working directory and will need to be checked in seperately"

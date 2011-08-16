The directory contains the standalone APS software.
It includes:

python - python interface
matlab - matlab interface
libaps - c library used by both the python and matlab interfaces

The matlab and libaps directories are currently empty. The libaps code 
currently lives at: 

../../common/src/+deviceDrivers/@APS/lib

The matlab code is in:

../../common/src/+deviceDrivers/@APS/
../../common/src/util/APSGui/
../../common/src/util/APSWaveform.m

Once a good way is found seperate the APS software from the experiment framework 
and still maintain compatibilty with the frame work the APS software will be 
consolidated here.

Python Requirements
-------------------

The python interface has been tested on Windows 7 using Python 2.6. It requires

pyside: http://www.pyside.org/
numpy:  http://numpy.scipy.org/
h5py:   https://code.google.com/p/h5py/





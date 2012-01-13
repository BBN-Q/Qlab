#!/bin/sh
#
# Script to convert APS python interface from python2.x to python 3
# Conversion is done in place

2to3 -w APScontrol.py
2to3 -w APSMatlabFile.py
2to3 -w aps.py

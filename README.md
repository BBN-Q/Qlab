Qlab measurement and control software
=====================================

A MATLAB framework for superconducting qubit systems.

Installation
------------
To get started, simply download and unzip the latest release. Or, if you want the tip of the development repository, clone a local copy with

	git clone git@github.com:BBN-Q/Qlab.git localname

The code is loosely organized into

* `analysis/` - routines for data analysis
* `experiment/` - experiment control and measurement
* `common/` - instrument drivers, pulse generation, and general utilities

Before running any of the scripts, add `basedir/common/src` and `basedir/common/src/util` to your MATLAB path. The pulse generation routines in `experiment/muWaveDection/sequences` further depend on setting a MATLAB preference for the path to a pulse configuration file. See the [pulse generation][Pulse-Generation] documentation for details.

See the [wiki][] for further help.

All source is distributed under the Apache open source [license][].

[wiki]: http://github.com/BBN-Q/Qlab/wiki
[Pulse-Generation]: http://github.com/BBN-Q/Qlab/wiki/Pulse-Generation
[license]: http://github.com/BBN-Q/Qlab/blob/master/LICENSE
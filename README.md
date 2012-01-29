Qlab measurement and control software
=====================================

Installation
------------
To get started, simply download and unzip the latest release. Or, if you want the tip of the development repository, clone a local copy with

	clone git@github.com:BBN-Q/Qlab.git localname

The code is loosely organized into

* `analysis/` - routines for data analysis
* `experiment/` - experiment control and measurement
* `common/` - instrument drivers, pulse generation, and general utilities

Before running any of the scripts, add `basedir/common/src` and `basedir/common/src/util` to your MATLAB path. The pulse generation routines in `experiment/muWaveDection/sequences` further depend on setting a MATLAB preference for the path to a pulse configuration file. See the [PatternGen][] documentation for details.

See the [wiki][] for further help.

[wiki]: github.com/BBN-Q/Qlab/wiki
[PatternGen]: github.com/BBN-Q/Qlab/wiki/PatternGen
# Qlab measurement and control software

A MATLAB framework for superconducting qubit systems.

## Installation

### Source Code

To get started, simply download and unzip the latest release. Or, if you want the tip of the development repository, clone a local copy with

	git clone git@github.com:BBN-Q/Qlab.git localname

Then move into the QLab directory and run the installQLab.m script to setup the preferences.  It will also prompt you with the correct folders to add to the path.

The code is loosely organized into

* `analysis/` - routines for data analysis
* `experiment/` - experiment control and measurement
* `common/` - instrument drivers, pulse generation, and general utilities

See the [wiki][] for further help.

All source is distributed under the Apache open source [license][].

### Binaries

We also distribute mex binaries for some accelerated data processing and dll's for the BBN-APS pulse sequencers.  These can be found here [binaries].

[wiki]: http://github.com/BBN-Q/Qlab/wiki
[Pulse-Generation]: http://github.com/BBN-Q/Qlab/wiki/Pulse-Generation
[license]: http://github.com/BBN-Q/Qlab/blob/master/LICENSE
[binaries]: [https://drive.google.com/folderview?id=0B5nllspmfYgUNWdMS1gwNW9nSXM&usp=sharing]

from distutils.core import setup
import py2exe

setup(windows=['APScontrol.py'],
	options={'py2exe': {
		'dll_excludes': ['libzmq.dll', 'MSVCP90.dll', 'libiomp5md.dll'],
		'excludes': ['Tkconstants','Tkinter','tcl', 'pyreadline'],
		'includes': ['numpy', 'PySide.QtXml', 'h5py.*'],
		'packages': ['numpy.core']
		}
	})
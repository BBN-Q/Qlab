"""
Created on Tue Mar 27 14:34:40 2012

@author: Colm Ryan 

Creates a table of low-pass filter coefficients for demodulating signal.

We design for a pass band of 1/2 the IF frequency and a stop-band of the IF frequency.
We arbitrarily accept 3dB of loss in the pass band and want 30dB of suppression in the stop band.
"""

import scipy.signal
import numpy as np

aCoeffList = []
bCoeffList = []
for IFFreq in np.arange(0.01, 1, 0.01):
    (b,a) = scipy.signal.iirdesign(IFFreq/2, IFFreq, 3, 30, ftype='butter')
    aCoeffList.append(a)
    bCoeffList.append(b)

print('a = [...')
for tmpCoeffs in aCoeffList:
    print('{0};...'.format(tmpCoeffs))


print('\n\nb = [...')
for tmpCoeffs in bCoeffList:
    print('{0};...'.format(tmpCoeffs))
    
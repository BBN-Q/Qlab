from PyDAQmx import *
import numpy

def take_data_2chan(num_points, sampling_rate):
	"""
	Take `num_points` from the NIDAQ
	"""

	analog_input = Task()
	read = int32()
	data_size = 2*num_points
	data = numpy.zeros((data_size), dtype=numpy.float64)

	# DAQmx Configure Code
	analog_input.CreateAIVoltageChan("Dev1/ai0:1", "", DAQmx_Val_RSE, -10.0, 10.0, DAQmx_Val_Volts, None)
	analog_input.CfgSampClkTiming("", sampling_rate, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps,num_points)

	# DAQmx Start Code
	analog_input.StartTask()

	# DAQmx Read Code
	analog_input.ReadAnalogF64(num_points,10.0, DAQmx_Val_GroupByChannel, data, data_size,byref(read),None)


	return data
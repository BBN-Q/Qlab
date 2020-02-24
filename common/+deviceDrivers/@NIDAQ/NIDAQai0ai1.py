from PyDAQmx import *
import numpy

def NIDAQai0ai1(num_points_perChan,sampling_rate_perChan):
    """
    Take `num_points` from the NIDAQ
    """
    taskHandle = TaskHandle(0)
    DAQmxCreateTask("",byref(taskHandle))
    read = int32()
    data_size = 2*num_points_perChan
    data = numpy.zeros((data_size), dtype=numpy.float64)

    # DAQmx Configure Code
    DAQmxCreateAIVoltageChan(taskHandle,"Dev1/ai0:1", "", DAQmx_Val_Cfg_Default, -10.0, 10.0, DAQmx_Val_Volts, None)
    DAQmxCfgSampClkTiming(taskHandle,"", sampling_rate_perChan, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps,num_points_perChan)

    # DAQmx Start Code
    DAQmxStartTask(taskHandle)

    return taskHandle
    
def getData(taskHandle,num_points_perChan):
    # DAQmx Read Code
    read = int32()
    data_size = 2*num_points_perChan
    data = numpy.zeros((data_size), dtype=numpy.float64)

    DAQmxReadAnalogF64(taskHandle,num_points_perChan, 10.0, DAQmx_Val_GroupByChannel, data, data_size, byref(read),None)
    return data

def killTask(taskHandle):
    # If the task is still alive kill it
    if taskHandle != 0:
        DAQmxStopTask(taskHandle)
        DAQmxClearTask(taskHandle)
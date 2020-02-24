from PyDAQmx import *
import numpy



def NIDAQai0(num_points,sampling_rate):
    """
    Take `num_points` from the NIDAQ
    """
    taskHandle = TaskHandle(0)
    DAQmxCreateTask("",byref(taskHandle))
    read = int32()
    data = numpy.zeros((num_points,), dtype=numpy.float64)

    # DAQmx Configure Code
    DAQmxCreateAIVoltageChan(taskHandle,"Dev1/ai0", "", DAQmx_Val_Cfg_Default, -10.0, 10.0, DAQmx_Val_Volts, None)
    DAQmxCfgSampClkTiming(taskHandle,"", sampling_rate, DAQmx_Val_Rising, DAQmx_Val_FiniteSamps,num_points)

    # DAQmx Start Code
    DAQmxStartTask(taskHandle)

    return taskHandle
    
def getData(taskHandle,num_points):
    # DAQmx Read Code
    read = int32()
    data = numpy.zeros((num_points,), dtype=numpy.float64)

    DAQmxReadAnalogF64(taskHandle,num_points, 10.0, DAQmx_Val_GroupByChannel, data, num_points, byref(read),None)
    return data

def killTask(taskHandle):
    # If the task is still alive kill it
    if taskHandle != 0:
        DAQmxStopTask(taskHandle)
        DAQmxClearTask(taskHandle)

function [dataA, dataB] = processBuffer(buffer, verticalScale)
% PROCESSBUFFER takes an input buffer of uint8s and splits into two output 
% buffers, dataA and dataB, that are doubles. It scales the input data
% from [0, 255] to (-Vs, Vs).
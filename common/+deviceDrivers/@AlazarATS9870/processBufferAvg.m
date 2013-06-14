function [dataA, dataB] = processBufferAvg(buffer, bufferDims, verticalScale)
% PROCESSBUFFERAVG
%  buffer - input buffer of uint8s
%  bufferDims - 4 element vector o[record length x waveforms x segments x round robins per buffer]
%  verticalScale - scale input data from [0, 255] to (-Vs, Vs).
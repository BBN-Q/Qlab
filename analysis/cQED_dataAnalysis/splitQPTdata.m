function [datamat, varmat] = splitQPTdata(data, numPulses, numCals)
%convert a single-expt. process tomo into a matrix compatible with
%analyzeProcessTomo

if ~iscell(data)
   nqubits = 1;
   datamat = cell(1,1);
   varmat = cell(1,1);
   datain = data;
   data = {};
   data{1} = datain;
else
   nqubits = 2;
   datamat = cell(3,1);
   varmat = cell(3,1);
end
    
totPulses = numPulses^nqubits;

for kk=1:size(data,2)
    datamat{kk} = zeros((totPulses+numCals),totPulses);
    for jj=1:totPulses
        datamat{kk}(1:totPulses,jj)=data{kk}(1+(jj-1)*totPulses:(jj)*totPulses);
        datamat{kk}(1+totPulses:totPulses+numCals,jj)=data{kk}(end-numCals+1:end);
        if isfield(data, 'realvar')
            varmat{kk}(1:totPulses,jj)=data.realvar{kk}(1+(jj-1)*totPulses:(jj)*totPulses);
            varmat{kk}(1+totPulses:totPulses+numCals,jj)=data.realvar{kk}(end-numCals+1:end);
        end
    end
    datamat{kk}=real(transpose(datamat{kk}));
end
end


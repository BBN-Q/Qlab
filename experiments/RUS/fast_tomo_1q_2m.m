function [bins, PDFvec, data_con, rhoa,rhob]=fast_tomo_1q_2m(cond, threshold, opcode, selectMeas, varargin)
%load tomo from single shots, postselect on ancilla
%cond = 1,-1,0 for conditioned (>, <), unconditioned
%threshold = ancilla value for postselection.
numSegmentsvec = [10,14];
ASegmentsvec = [[14;16],[11;13]];
calSegmentsvec = [4,8];
numSegments = numSegmentsvec(opcode); %44; %including calibrations (data + ancilla)
ASegments = ASegmentsvec(:,opcode); %[37;41]; %segments with A in 0 and 1, used to find opt. threshold
calSegments = calSegmentsvec(opcode); %8; %%number of calibrations
numTomo = 10; %subset of segments with tomography + calibrations (not including ancilla)

if ~isempty(varargin)
    data = load_data(varargin{1});
else
    data=load_data('latest');
end
alldata=reshape_cells(data);
if any(cond)
    docond=1;
else
    docond=0;
end
datatemp.data=[]; datatemp.realvar=[];
[bins,PDFvec,data_con,var_con,~,datamat,~,~,~]=initByMsmt_2D(alldata,1,numSegments,2,ASegments,selectMeas,cond,threshold,docond,calSegments);
datatemp.data{1}=data_con{1}(1:numTomo,1);
datatemp.realvar{1}=var_con{1}(1:numTomo,1);
[rhoa,rhob]= analyzeStateTomo(datatemp,1,6,2);
end
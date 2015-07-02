function [Zmat, fidvec, betas] = analyze_twirl(data, gateseq, nqubits)
%analyze data produced by twirl_seq

%gateseq = name of sequence corresponding to the .csv file containing the
%Clifford indeces and the measurement operators

%indvec = [3,1,2]; %indeces for measurements for M1, M2, M3, M12, M23, M13, M123... sorting is unnecessary
indvec=1:2^nqubits-1;  %if all qubits and correlations are measured
segnum=data.expSettings.sweeps.SegmentNumWithCals.numPoints-data.expSettings.sweeps.SegmentNumWithCals.numCals;
calRepeat = 1; %number of repetition per calibration sequence

%example of M for nqubits=2
% M = [ 1  1  1  1  0  0  0  0  0  0  0  0;
%       0  0  0  0  1  1  1  1  0  0  0  0;
%       0  0  0  0  0  0  0  0  1  1  1  1;
%       1 -1  1 -1  0  0  0  0  0  0  0  0;
%       0  0  0  0  1 -1  1 -1  0  0  0  0;
%       0  0  0  0  0  0  0  0  1 -1  1 -1;
%       1  1 -1 -1  0  0  0  0  0  0  0  0;
%       0  0  0  0  1  1 -1 -1  0  0  0  0;
%       0  0  0  0  0  0  0  0  1  1 -1 -1;
%       1 -1 -1  1  0  0  0  0  0  0  0  0;
%       0  0  0  0  1 -1 -1  1  0  0  0  0;
%       0  0  0  0  0  0  0  0  1 -1 -1  1];
  

measOp = dec2bin(0:2^nqubits-1, nqubits);

%building the beta matrix

M=zeros(2^nqubits*(2^nqubits-1));
for jj=1:2^nqubits*(2^nqubits-1)
    for kk=(mod(jj-1,2^nqubits-1))*(2^nqubits)+1:(mod(jj-1,2^nqubits-1))*(2^nqubits)+2^nqubits
        temp=measOp(kk-mod((jj-1),2^nqubits-1)*(2^nqubits),:);
        temp=temp(:);
        temp2=measOp(ceil(jj/(2^nqubits-1)),:);
        temp2=temp2(:);
        M(jj,kk) = -2*(mod(bin2dec(temp)'*bin2dec(temp2),2))+1;
    end
end

Mcals = zeros(2^nqubits, 2^nqubits-1); 
for kk=1:2^nqubits-1
    Mcals(:,kk) = mean(reshape(real(data.data{indvec(kk)}(segnum+1:end)), calRepeat, 2^nqubits), 1);
end

Mcals = transpose(Mcals);

offvec = mean(Mcals,2);

Mcals = Mcals - repmat(offvec,1,2^nqubits);

Mcals = Mcals(:);

betas = M\Mcals;

Mop = reshape(betas, 2^nqubits, 2^nqubits-1)';

Mop = Mop(:, 2:end);
Zmat = zeros(segnum,2^nqubits-1);

Mvec = zeros(2^nqubits-1,1);
for ii = 1:segnum
    for kk=1:2^nqubits-1
    Mvec(kk) =  real(data.data{indvec(kk)}(ii))-betas(1+(kk-1)*2^nqubits);
    end
    Mvec = Mvec - offvec;
    Zmat(ii,:) = Mop \ Mvec;  
 end

seqfile = strcat('C:/users/qlab/Documents/Julia/Twirl/twirl_',gateseq,'.csv');
seq = fopen(seqfile,'r');

%saves a copy of the file with list of cliffords and measurements

[~,datafilename,~]=fileparts(data.filename);
copyfile(seqfile, fullfile(data.path, strcat(datafilename,'.csv'))); 

%read the sequence files
strscan = '%f';
for ii=1:2*nqubits-1
    strscan = strcat(strscan,',%f');
end
strscan = strcat(strscan, ',%s');
seqmat = textscan(seq,strscan);
measvec = seqmat{2*nqubits+1};
fclose(seq);

fidvec = zeros(segnum,1);

for ii = 1:segnum
    thismeas = measvec{ii};
    for ind = 1:length(thismeas)-1
        switch thismeas(ind+1)
            case 'I'
                bincode(ind)='0';
            case 'Z'
                bincode(ind)='1';
        end
    parind = bin2dec(bincode);
    end
    switch thismeas(1)
        case '+'
            fidvec(ii)=Zmat(ii,parind);
        case '-'
            fidvec(ii)=-Zmat(ii,parind);
    end
end
save(fullfile(data.path, strcat(datafilename,'_fid.txt')), '-ASCII', 'fidvec');
            

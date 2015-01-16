function analyzeCalCR(caltype, CRdata,channel,fighandle)
%simple fit function to get optimum length/phase in a CR calibration
%and set in pulse params

%caltype: 
% 1 - length
% 2 - phase

%channel: X6 channel with the target data (1 or 2)

%dataSource = 'II_1_1_1';

CRpulsename = 'CR12';

data = real(CRdata.data{channel});   %TO FIX: how to relate channel to dataSource?
xpoints = CRdata.xpoints{channel}(1:(length(data)-8)/2);
data = cal_scale(data,4); %num repeats. Assuming the calibrations are 4 |0>, then 4 |1>. Need
%to be generalized to different cal. seqs

data0 = data(1:length(data)/2);
data1 = data(length(data)/2+1:end);

sinf = @(p,t) p(1)*cos(2*pi/p(2)*t+p(3))+p(4);
p=[1,xpoints(end),0,0];

%fit sine curves
[beta0,~,~] = nlinfit(xpoints, data0(:),sinf,p);
[beta1,~,~] = nlinfit(xpoints, data1(:),sinf,p);
%todo: make fit xpoints finer
yfit0 = sinf(beta0,xpoints);
yfit1 = sinf(beta1,xpoints);

if(caltype==1) 
    %find the first zero crossing
    %dyfit0 = diff(yfit0); dyfit1 = diff(yfit1);
    %find(dyfit0>0)
    %yfit0c = yfit0(1:
    yfit0c = yfit0(1:round(beta0(2)/2/(xpoints(2)-xpoints(1)))); %select the first half period 
    yfit1c = yfit1(1:round(beta1(2)/2/(xpoints(2)-xpoints(1))));
    [~, indmin0] = min(abs(yfit0c(:)));  %min returns the index of the first zero crossing
    [~, indmin1] = min(abs(yfit1c(:)));  %min returns the index of the first zero crossing
    optlen = mean([xpoints(indmin0),xpoints(indmin1)]);
    fprintf('Length index for CNOT = %f\n', mean([indmin0, indmin1])); 
    fprintf('Optimum length = %f ns\n', optlen)
    fprintf('Mismatch between |0> and |1> = %f ns\n', abs(xpoints(indmin1)-xpoints(indmin0)))
elseif(caltype==2)
    %find max contrast
    ctrfit = yfit0-yfit1;
    [~, indmax] = max(ctrfit);
    optphase = xpoints(indmax);
    fprintf('Phase index for maximum contrast = %d\n', indmax)
    fprintf('Optimum phase = %f\n', optphase)
else
    frpintf('Calibration type not supported')
    return
end

figure(fighandle);  %I need to find a consistent way to deal with plots, DR
plot(xpoints, data0, 'b.', xpoints, data1, 'r.', xpoints, yfit0, 'b-', xpoints, yfit1, 'r-','MarkerSize',16);
legend('ctrlQ in |0>','ctrlQ in |1>');
ylim([-1,1]); ylabel('<Z>'); 

if(caltype==1)
    xlabel ('CR flat pulse length (ns)');
else
    xlabel ('Phase (deg)');
end
title(strrep(CRdata.filename, '_', '\_'));

%update length/phase in CR pulse parameters
warning('off', 'json:fieldNameConflict');
channelLib = json.read(getpref('qlab','ChannelParamsFile'));
warning('on', 'json:fieldNameConflict');
chDict = channelLib.channelDict;
if(caltype==1)
    outlen = optlen;
    outphase = chDict.(CRpulsename).pulseParams.phase;
else
    outlen = chDict.(CRpulsename).pulseParams.length;
    outphase = optphase;
end
updateLengthPhase(CRpulsename, outlen, outphase);
end
function optvalue = analyzeCalCR(caltype, CRdata,channel, varargin)
%simple fit function to get optimum length/phase in a CR calibration
%and set in pulse params

%caltype: 
% 1 - length
% 2 - phase

%channel: channel with the target data

CRpulsename = 'CR';

data = real(CRdata.data{channel});   
xpoints = CRdata.xpoints{channel}(1:(length(data)-8)/2);
data = cal_scale(data,4); %Assuming the calibrations are 4 |0>, then 4 |1>.

data0 = data(1:length(data)/2);
data1 = data(length(data)/2+1:end);

sinf = @(p,t) p(1)*cos(2*pi/p(2)*t+p(3))+p(4);

if(caltype==1)
    p=[1,4*xpoints(end),0,0];
else
    p=[1,xpoints(end),0,0];
end

%fit sine curves
[beta0,~,~] = nlinfit(xpoints, data0(:),sinf,p);
[beta1,~,~] = nlinfit(xpoints, data1(:),sinf,p);
%todo: make fit xpoints finer
yfit0 = sinf(beta0,xpoints);
yfit1 = sinf(beta1,xpoints);

if(caltype==1) 
    yfit0c = yfit0(1:min(round(abs(beta0(2))/2/(xpoints(2)-xpoints(1))),end)); %select the first half period or less
    yfit1c = yfit1(1:min(round(abs(beta1(2))/2/(xpoints(2)-xpoints(1))),end));
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

if nargin>3
    figure(varargin{1});  %I need to find a consistent way to deal with plots, DR
else
    figure(101)
end
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
    outlen = optlen*1e-9;
    outphase = chDict.(CRpulsename).pulseParams.phase;
    optvalue = optlen;
else
    outlen = chDict.(CRpulsename).pulseParams.length;
    outphase = optphase;
    optvalue = optphase;
end
updateLengthPhase(CRpulsename, outlen, outphase);
end
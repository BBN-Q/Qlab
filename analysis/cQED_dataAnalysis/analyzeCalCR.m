function [optvalue, contrast] = analyzeCalCR(caltype, CRdata,channel, CRname)
%simple fit function to get optimum length/phase in a CR calibration
%and set in pulse params

%caltype: 
% 1 - length
% 2 - phase
% 3 - amplitude

%channel: channel with the target data

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

CRpulsename = CRname;

data = real(CRdata.data{channel});   
xpoints = CRdata.xpoints{channel}(1:(length(data)-8)/2);
data = cal_scale(data,4); %Assuming the calibrations are 4 |0>, then 4 |1>.

data0 = data(1:length(data)/2);
data1 = data(length(data)/2+1:end);

sinf = @(p,t) p(1)*cos(2*pi/p(2)*t+p(3))+p(4);

if(caltype==1)
    p=[1,2*xpoints(end),-pi/4,0];
else
    p=[1,xpoints(end),pi,0];
end

%fit sine curves
xpoints_f = linspace(xpoints(1),xpoints(end),1001);
if(caltype<3)
    [beta0,~,~] = nlinfit(xpoints, data0(:),sinf,p);
    [beta1,~,~] = nlinfit(xpoints, data1(:),sinf,p);
    yfit0 = sinf(beta0,xpoints);
    yfit1 = sinf(beta1,xpoints);
    yfit0_f = sinf(beta0,xpoints_f);
    yfit1_f = sinf(beta1,xpoints_f);
elseif(caltype==3)
    beta0 = polyfit(xpoints, data0(:),1);
    beta1 = polyfit(xpoints, data1(:),1);
    yfit0_f = beta0(2)+beta0(1)*xpoints_f;
    yfit1_f = beta1(2)+beta1(1)*xpoints_f;
end

if(caltype==1) 
    yfit0c = yfit0(1:min(round(abs(beta0(2))/2/(xpoints(2)-xpoints(1))),end)); %select the first half period or less
    yfit1c = yfit1(1:min(round(abs(beta1(2))/2/(xpoints(2)-xpoints(1))),end));
    [~, indmin0] = min(abs(yfit0c(:)));%-beta0(4));  %min returns the index of the first zero crossing
    [~, indmin1] = min(abs(yfit1c(:)));%-beta1(4));  %min returns the index of the first zero crossing
    optlen = round(mean([xpoints(indmin0),xpoints(indmin1)])/10)*10;
    fprintf('Length index for CNOT = %f\n', mean([indmin0, indmin1])); 
    fprintf('Optimum length = %f ns\n', optlen)
    fprintf('Mismatch between |0> and |1> = %f ns\n', abs(xpoints(indmin1)-xpoints(indmin0)))
    CRfigname = 'CRlength';
elseif(caltype==2)
    %find max contrast
    ctrfit = yfit0_f-yfit1_f;
    [maxctr, indmax] = max(ctrfit);
    optphase = xpoints_f(indmax)-180; %set the phase for ZX90
    fprintf('Phase index for maximum contrast = %d\n', indmax)
    fprintf('Optimum phase = %f\n', optphase)
    fprintf('Contrast = %f\n', maxctr/2);
    CRfigname = 'CRphase';
elseif(caltype==3)
    optamp = -(beta0(2)+beta1(2))/(beta0(1)+beta1(1));
    fprintf('Optimum amplitude = %f\n', optamp)
    CRfigname = 'CRamplitude';
else
    frpintf('Calibration type not supported')
    return
end

if ~isfield(figHandles, CRfigname) || ~ishandle(figHandles.(CRfigname))
    figHandles.(CRfigname) = figure('Name', CRfigname);
else
    figure(figHandles.(CRfigname)); clf;
end
plot(xpoints, data0, 'b.', xpoints, data1, 'r.', xpoints_f, yfit0_f, 'b-', xpoints_f, yfit1_f, 'r-','MarkerSize',16);
legend('ctrlQ in |0>','ctrlQ in |1>');
ylim([-1,1]); ylabel('<Z>'); 

if(caltype==1)
    xlabel ('CR flat pulse length (ns)');
elseif(caltype==2)
    xlabel ('Phase (deg)');
elseif(caltype==3)
    xlabel('Amplitude (V)');
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
    outamp = chDict.(CRpulsename).pulseParams.amp;
    optvalue = optlen;
    contrast = NaN;
elseif(caltype==2)
    outlen = chDict.(CRpulsename).pulseParams.length;
    outamp = chDict.(CRpulsename).pulseParams.amp;
    outphase = optphase;
    optvalue = optphase;
    contrast = maxctr/2;
elseif(caltype==3)
    outlen = chDict.(CRpulsename).pulseParams.length;
    outphase = chDict.(CRpulsename).pulseParams.phase;
    outamp = optamp;
    optvalue = optamp;
    contrast = NaN;
end
updateLengthPhase(CRpulsename, outlen, outphase, outamp);
end
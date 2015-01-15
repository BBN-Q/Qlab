function optphase = analyzeCalCR(CRdata,channel)
%simple fit function to get optimum phase in a CR calibration
%and set in pulse params

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
[beta0,r0,j0] = nlinfit(xpoints, data0(:),sinf,p);
[beta1,r1,j1] = nlinfit(xpoints, data1(:),sinf,p);
yfit0 = sinf(beta0,xpoints);
yfit1 = sinf(beta1,xpoints);

%find max contrast
ctrfit = yfit0-yfit1;
[ctrmax, indmax] = max(ctrfit);
optphase = xpoints(indmax);
fprintf('Phase index for maximum contrast = %f\n', indmax)
fprintf('Optimum phase = %f\n', optphase)

figure(getpref('plots','CRHandle'));
plot(xpoints, data0, 'b.', xpoints, data1, 'r.', xpoints, yfit0, 'b-', xpoints, yfit1, 'r-');
legend('ctrlQ in |0>','ctrlQ in |1>');
ylim([-1,1]); ylabel('<Z>'); xlabel ('Phase (deg)');

%update phase in CR pulse parameters
warning('off', 'json:fieldNameConflict');
channelLib = json.read(getpref('qlab','ChannelParamsFile'));
warning('on', 'json:fieldNameConflict');
chDict = channelLib.channelDict;
updateLengthPhase(CRpulsename, chDict.(CRpulsename).pulseParams.length, optphase);
end
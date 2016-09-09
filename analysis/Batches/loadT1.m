%load T1 in multiple, consecutive files
function [T1, dT1] = loadt1(startnum, stopnum, varargin)
numcal = 4; %number of normalization points
foldername = 'IBMv11_2037W3';
datestr = '150716';
expname = 'T1_q5';
quad = 'real';
if nargin>2
    deltanum=varargin{1};
else
    deltanum=1;
end

T1 = zeros(1,floor((stopnum-startnum)/deltanum)+1); %initialize arrays of T1 and error bars
dT1 = zeros(1,floor((stopnum-startnum)/deltanum)+1);
kk=1;

for filenum = startnum:deltanum:stopnum
    data = load_data(strcat('C:\Users\qlab\Documents\data\',foldername,'\',num2str(datestr),'\',num2str(filenum),'_',foldername,'_',expname,'.h5'));
    ydata = cal_scale(data.data);
    if quad == 'real'
        normdata = real(ydata);
    else
        normdata = imag(ydata);
    end
    [T1(kk),dT1(kk)] = fitt1(data.xpoints(1:length(data.xpoints)-numcal), real(ydata));
    drawnow;

    kk=kk+1;
end

xaxis = startnum:deltanum:stopnum;
figure()
errorbar(xaxis,T1/1000,dT1/1000,'.-','MarkerSize',12);
ylim([0,inf]);
xlim([startnum,stopnum]);
xlabel('File number');
ylabel('T1 (us)');
annotation('textbox','string',datestr)
fprintf('Average T1 = %.1f us\n', mean(T1/1000));

setpref('plots','doplots',0) %disable plots

numcal = 4; %number of normalization points
datestr = '150108';
expname = 'T1Q1';
quad = 'real';
startnum = 1645;
stopnum = 1845;

T1 = zeros(1,stopnum-startnum+1); %initialize arrays of T1 and error bars
dT1 = zeros(1,stopnum-startnum+1);
kk=1;

for filenum = startnum:stopnum
    data = load_data(strcat('C:\Users\qlab\Documents\data\IBM_v11\',num2str(datestr),'\',num2str(filenum),'_IBM_v11_',expname,'.h5'));
    ydata = cal_scale(data.data);
    if quad == 'real'
        normdata = real(ydata);
    else
        normdata = imag(ydata);
    end
    [T1(kk),dT1(kk)] = fitt1(data.xpoints(1:length(data.xpoints)-4), real(ydata));
    kk=kk+1;
end

xaxis = startnum:stopnum;
figure()
errorbar(xaxis,T1/1000,dT1/1000,'.-','MarkerSize',15);
ylim([0,inf]);
xlim([startnum,stopnum]);
xlabel('File number');
ylabel('T1 (us)');
annotation('textbox','string',datestr)

fprintf('Average T1 = %.1f us', mean(T1/1000));

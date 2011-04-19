function [t1, t1error] = fitt1(xdata, ydata)
% extract and fit sliding T1
% usage: [t1, t1error] = fitt1(data, xstart, xend)

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
end
xdata = xdata(:);
y = ydata;

% subtract offset
endpoint = mean(y(end-10:end));

y(:) = y(:) - endpoint;

% Model: A Exp(-t/tau) + offset
t1f = inline('p(1)*exp(-tdata/p(2)) + p(3)','p','tdata');

% if xdata is a single value, assume that it is the time step
if length(xdata) == 1
    xdata = 0:xdata:xdata*(length(y)-1);
end
p = [max(y)-min(y) max(xdata)/3. 0];

tic
[beta,r,j,cov] = nlinfit(xdata, y, t1f, p);
toc

figure
subplot(3,1,2:3)
plot(xdata,y,'o')
hold on
plot(xdata,t1f(beta,xdata),'-r')
xlabel('Time [ns]')
ylabel('Amp [V]')
hold off
%plot residuals
subplot(3,1,1)
bar(xdata, r)
axis tight
ylabel('Residuals [V]')
xlabel('Time [ns]')

t1 = beta(2);
ci = nlparci(beta,r,j);
t1error = (ci(2,2)-ci(2,1))/2;
fprintf('Covariance matrix:\n');
disp(cov)

% annotate the graph with T_1 result
subplot(3,1,2:3)
text(xdata(end-1), max(y), sprintf('T_1 = %.0f +/- %.0f ns', t1, t1error), ...
    'HorizontalAlignment', 'right');

% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);
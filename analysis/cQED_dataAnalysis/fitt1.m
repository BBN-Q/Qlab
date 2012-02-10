function [t1, t1error] = fitt1(xdata, ydata)
% extract and fit sliding T1
% usage: [t1, t1error] = fitt1(data, xstart, xend)

% if no input arguments, try to get the data from the current figure
if nargin < 2
    h = gcf;
    line = findall(h, 'Type', 'Line');
    xdata = get(line(1), 'xdata');
    ydata = get(line(1), 'ydata');
    % save figure title
    plotTitle = get(get(gca, 'Title'), 'String');
else
    h = figure;
    plotTitle = '';
end
xdata = xdata(:);
y = ydata(:);

% subtract offset
%endpoint = mean(y(end-10:end));
%y(:) = y(:) - endpoint;

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

figure(h)
clf
subplot(3,1,2:3)
plot(xdata/1e3,y,'o')
hold on
plot(xdata/1e3,t1f(beta,xdata),'-r')
xlabel('Time [\mus]')
ylabel('<\sigma_z>')
hold off
%plot residuals
subplot(3,1,1)
bar(xdata/1e3, r)
axis tight
ylabel('<\sigma_z>')
xlabel('Time [\mus]')
title(plotTitle)

t1 = beta(2);
ci = nlparci(beta,r,j);
t1error = (ci(2,2)-ci(2,1))/2;
fprintf('Covariance matrix:\n');
disp(cov)

% annotate the graph with T_1 result
subplot(3,1,2:3)
text(xdata(end-1)/1e3, 0.9*max(y), sprintf('T_1 = %.1f +/- %.1f us', t1/1e3, t1error/1e3), ...
    'HorizontalAlignment', 'right', 'FontSize',12);

% if you want confidence bands, use something like:
% ci = nlparci(beta,r,j);
% [ypred,delta] = nlpredci(rabif,x,beta,r,j);
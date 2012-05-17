function [bestOffset, fitPts] = find_null_offset(measPowers, xPts)
%Find the offset corresponding to the minimum power with some simple
%fitting

%Setup the fitting function
fitFcn = @(a,x)(10*log10(a(1)*(x-a(2)).^2+a(3)));

%Take a guess from the minimum value and fit
[minValue, minIndex] = min(measPowers);
aFit = nlinfit(xPts, measPowers, fitFcn, [1, xPts(minIndex), 10^(minValue/10)]);

bestOffset = aFit(2);
fitPts = fitFcn(aFit, xPts);

end

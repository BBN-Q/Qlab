% FILE: fitSeqFid0.m

function [beta,r1,r2] = fitSeqFidCross(seqlengths,ydat,plotflag)
%this function fits the zeroth order benchmarking formula

initialGuess=[0.9933 0.99353 0.25 0.25 0.25 0.25];

[beta, r, j] = nlinfit(seqlengths, ydat, @(p, seqlengths) model(seqlengths,p), initialGuess);

if plotflag
    figure
    yfit = model(seqlengths, beta);
    offset = beta(6);
    plot(seqlengths,log(ydat-offset),seqlengths,log(yfit-offset),'r')
    ylabel('ave fid')
    xlabel('gate number')
end

p1=beta(1);
p2=beta(2);
r1=1/2-p1/2
r2=1/2-p2/2

re1=1/2-p1/2 - (1/2-0.9933/2)
re2=1/2-p2/2- (1/2-0.9935/2)
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function yfit = model(n,vec)

a = vec(4);
p1 = vec(1);

b = vec(5);
p2 = vec(2);
c = vec(3);
offset = vec(6);

yfit = offset + a*p1.^n + b*p2.^n + c*(p1*p2).^n;

end


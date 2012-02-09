% FILE: fitSeqFid0.m

function [beta,r1,r2] = fitSeqFidCross(seqlengths,ydat,plotflag)
%this function fits the zeroth order benchmarking formula

initialGuess=[0.99 0.99, 0.0, 0.0, 0.0, 0.0];

[beta, r, j] = nlinfit(seqlengths, ydat(:), @(p, seqlengths) model(seqlengths,p), initialGuess);


if plotflag
    %figure
    yfit = model(seqlengths, beta);
    yfit = reshape(yfit, length(seqlengths), 4);
    %offset = beta(6);
%    offset = 0.25;
%    semilogy(seqlengths,ydat-offset,seqlengths,yfit-offset,'r')
    hold on
    plot(seqlengths,yfit(:,1),'b')
    plot(seqlengths,yfit(:,2),'r')
    plot(seqlengths,yfit(:,3),'g')
    plot(seqlengths,yfit(:,4),'k')
    hold off
    xlim([0 max(seqlengths)])
    ylim([-0.05 1.05])
end

p1=beta(1);
p2=beta(2);
r1=1/2-p1/2
r2=1/2-p2/2

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function yfit = model(n,vec)

%Vec of parameters [p1, p2] (prop of no error)
% 00 pop is prob. of (no error)*(no error)
p1 = vec(1);
p2 = vec(2);
offset00 = vec(3);
offset01 = vec(4);
offset10 = vec(5);
offset11 = vec(6);

fit00 = (p1.^n+1)/2 .* (p2.^n +1)/2 + offset00;
fit01 = (p1.^n+1)/2 .* (1/2-(p2.^n)/2) + offset01;
fit10 = (1/2-(p1.^n)/2) .* (p2.^n +1)/2 + offset10;
fit11 = (1/2-(p1.^n)/2) .* (1/2-(p2.^n)/2) + offset11;

yfit = [fit00, fit01, fit10, fit11];

yfit = yfit(:);
end



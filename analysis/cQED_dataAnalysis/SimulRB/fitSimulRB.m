% FILE: fitSeqFid0.m

function [beta,r1,r2,yfit] = fitSimulRB(seqlengths,ydat,plotflag)
%this function fits the zeroth order benchmarking formula

initialGuess=[0.01 0.01, 0.0, 0.0, 0.0, 0.0, 0.0];

[beta, r, j] = nlinfit(seqlengths, ydat(:), @(p, seqlengths) model(seqlengths,p), initialGuess);

% get confidence intervals
ci = nlparci(beta,r,j);
cis = (ci(:,2)-ci(:,1))./2;

if plotflag
    %figure
    %yfit = model(seqlengths, beta);
    %yfit = reshape(yfit, length(seqlengths), 4);
    yfit = model(1:max(seqlengths), beta);
    yfit = reshape(yfit, max(seqlengths), 4);
    %offset = beta(6);
%    offset = 0.25;
%    semilogy(seqlengths,ydat-offset,seqlengths,yfit-offset,'r')
    hold on
    plot(yfit(:,1),'b')
    plot(yfit(:,2),'r')
    plot(yfit(:,3),'g')
    plot(yfit(:,4),'k')
    hold off
    xlim([0 max(seqlengths)])
    ylim([-0.05 1.05])
end

r1=beta(1);
r2=beta(2);
r12=beta(3);

fprintf('r1 = %.04f +/- %.04f, r2 = %.04f +/- %.04f, r12 = %.04f +/- %.04f\n', [r1 cis(1) r2 cis(2), r12, cis(3)]);
fprintf('Offsets:\n');
disp(beta(4:7))

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function yfit = model(n,vec)

%Vec of parameters [p1, p2] (prop of no error)
% 00 pop is prob. of (no error)*(no error)
r1 = vec(1);
r2 = vec(2);
r12 = vec(3);

propMat = [[-r1-r2-r12, +r2, +r1, +r12]; ...
           [r2, -r1-r2-r12, r12, r1];...
           [r1, r12, -r1-r2-r12, r2];...
           [r12, r1, r2, -r1-r2-r12]];
              
yfit = zeros(4,11);

for ct = 1:length(n)
    yfit(:,ct) = expm(n(ct)*propMat)*[1; 0; 0; 0];
end

yfit = yfit + repmat(vec(4:7)', 1,length(n));
yfit = yfit';
yfit = yfit(:);
end

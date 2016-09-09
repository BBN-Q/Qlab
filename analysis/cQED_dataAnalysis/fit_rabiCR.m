%% unrestricted fit
function [params_min, rfit] = fit_rabiCR(tvec,rvec,params_guess)
residue = @(params) calculateResidue_CR(params,tvec,rvec);
search_options = optimset('Display','final','MaxIter',2000);
params_min = fminsearch(residue,params_guess,search_options);
[~,xfit,yfit,zfit] = calculateResidue_CR(params_min,tvec,rvec);
rfit = [xfit,yfit,zfit];
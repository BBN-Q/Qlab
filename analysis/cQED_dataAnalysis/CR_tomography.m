function fitres_mat = CR_tomography(path, filename, startnum, tvec, phvec, varargin)
%load and analyzes data for cross-resonance gate tomography (Sheldon et al, arXiv:1603.04821)

%tvec: array of time steps for CR pulse
%phvec: array of phases for CR pulse

persistent figHandles
if isempty(figHandles)
    figHandles = struct();
end

p = inputParser;
addParameter(p,'plotNum',0,@isnumeric)
parse(p, varargin{:});
plotNum = p.Results.plotNum;

params_estimate =  [-0.0055, 0.0055, 0, 0, 0, 1.0000]; %initial parameter estimate
IX = zeros(21,1);
IY = zeros(21,1);
IZ = zeros(21,1);
ZX = zeros(21,1);
ZY = zeros(21,1);
ZZ = zeros(21,1);
fitres_mat = zeros(21,6,2);

for k=1:length(phvec)
    filenum = startnum+k-1;
    if k>1
        params_estimate =  fitres_0; %update estimate with last fit
    end
    data=load_data(fullfile(path, [num2str(filenum) filename num2str(k) '.h5']));
    caldata = real(cal_scale(data.data{1}));
    npoints=length(tvec);

    xvec=zeros(npoints,2);
    xvec(:,1) = caldata(1:npoints);
    xvec(:,2) = caldata(npoints+1:2*npoints);
    yvec(:,1) = caldata(2*npoints+1:3*npoints);
    yvec(:,2) = caldata(3*npoints+1:4*npoints);
    zvec(:,1) = caldata(4*npoints+1:5*npoints);
    zvec(:,2) = caldata(5*npoints+1:6*npoints);
    rvec = sqrt(sum(xvec,2).^2+sum(yvec,2).^2+sum(zvec,2).^2)*0.5;

    if k == plotNum %select which phase to plot, if any
        if ~isfield(figHandles, 'RabiCR') || ~ishandle(figHandles.('RabiCR'))
            figHandles.('RabiCR') = figure('Name', 'RabiCR');
            h = figHandles.('RabiCR');
        else
            h = figure(figHandles.('RabiCR')); clf;
        end
        figure(h);
        subplot(4,1,1)
        plot(tvec,xvec)
        title(strrep(data.filename, '_', '\_'))
        ylim([-1.1,1.1])
        ylabel('<X>')
        subplot(4,1,2)
        plot(tvec,yvec)
        ylabel('<Y>')
        ylim([-1.1,1.1])
        subplot(4,1,3)
        plot(tvec,zvec)
        ylabel('<Z>')
        ylim([-1.1,1.1])
        subplot(4,1,4)
        ylim([-1.1,1.1])
        plot(tvec,rvec)
        ylim([-0.1,1.1])
        ylabel('|R|')
        xlabel('Time (ns)')
    end
    
    [fitres_0, ~] = fit_rabiCR(tvec,[xvec(:,1), yvec(:,1), zvec(:,1)],params_estimate);
    params_estimate(1)=-params_estimate(1);
    params_estimate(2)=-params_estimate(2);
    [fitres_1, ~] = fit_rabiCR(tvec,[xvec(:,2), yvec(:,2), zvec(:,2)],params_estimate);
    IX(k) = (fitres_0(1)+fitres_1(1))/2/(2*pi)*1e3;
    IY(k) = (fitres_0(2)+fitres_1(2))/2/(2*pi)*1e3;
    IZ(k) = (fitres_0(3)+fitres_1(3))/2/(2*pi)*1e3;
    ZX(k) = (fitres_0(1)-fitres_1(1))/2/(2*pi)*1e3;
    ZY(k) = (fitres_0(2)-fitres_1(2))/2/(2*pi)*1e3;
    ZZ(k) = (fitres_0(3)-fitres_1(3))/2/(2*pi)*1e3;
    fitres_mat(k,:,1) = fitres_0;
    fitres_mat(k,:,2) = fitres_1;
end

if ~isfield(figHandles, 'CRfit') || ~ishandle(figHandles.('CRfit'))
    figHandles.('CRfit') = figure('Name', 'CRfit');
    h2 = figHandles.('CRfit');
else
    h2 = figure(figHandles.('CRfit')); clf;
end
figure(h2);
plot(phvec,ZZ,'.-',phvec,ZY,'.-',phvec,ZX,'.-',phvec,IZ,'.-',phvec,IY,'.-',phvec,IX,'.-')
ylabel('Interaction strength (MHz)');
xlabel('Phase of CR drive (deg)');
legend('ZZ','ZY','ZX','IZ','IY','IX');
end
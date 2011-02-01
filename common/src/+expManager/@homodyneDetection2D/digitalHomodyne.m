%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  digitalHomodyne.m
 %
 % Author/Date : Jerry Moy Chow / October 19, 2010
 %
 % Description : This function implements single channel digital homodyne
 % Takes only a single channel of the data, either the I or Q 
 % and digitally mixes into two single points, a digital I and Q,
 % based on the total size of the dataset
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %    10-19-2010  BRJ   Integration into qlab framework
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function implements single channel digital homodyne
% Takes only a single channel of the data, either the I or Q (default to
% the I) and digitally mixes into two single points, a digital I and Q,
% based on the total size of the dataset

function [DI DQ] =  digitalHomodyne(obj, signal, IFfreq, sampInterval, integrationStart, integrationWindow)
    % first define a variable that takes the total length of the signal
    if nargin < 5
        L = size(signal,1);
		integrationStart = 1;
    else
        L = integrationWindow;
    end
    
    % loop through segments
    DI = zeros(size(signal,2), 1);
    DQ = DI;
    for i = 1:size(signal,2)
        truncatesignal = signal(integrationStart:integrationStart+L-1, i);
        % define a time array with the same length as the signal but spaced at the
        % sampling time
        time = (0:L-1)*sampInterval;
        % define both a Sin and a Cos at the IFfreq with length L
        COS = cos(2*pi*time*IFfreq)';
        SIN = sin(2*pi*time*IFfreq)';
        % perform the discrete sum to obtain the digital I and digital Q signal
        DI(i) = (2/L)*sum(COS.*truncatesignal);
        DQ(i) = (2/L)*sum(SIN.*truncatesignal);
    end
end
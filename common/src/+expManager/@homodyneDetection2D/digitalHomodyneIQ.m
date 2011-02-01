%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Module Name :  digitalHomodyneIQ.m
 %
 % Author/Date : Blake Johnson / November 16, 2010
 %
 % Description : This function implements dual channel digital homodyne
 % Takes both I and Q channels and analyses in a frame rotating at the IF 
 % frequency. Finds and returns the mean value.
 %
 % Version: 1.0
 %
 %    Modified    By    Reason
 %    --------    --    ------
 %
 %
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [DI DQ] =  digitalHomodyneIQ(obj, isignal, qsignal, IFfreq, sampInterval, integrationStart, integrationWindow)
    % first define a variable that takes the total length of the signal
    if nargin < 6
        L = length(isignal);
		integrationStart = 1;
    else
        L = integrationWindow;
    end
    
    % loop through the segments
    DI = zeros(size(isignal,2), 1);
    DQ = DI;
    for i = 1:size(isignal,2)
        % truncate the I and Q signals to the integration window
        thisI = isignal(integrationStart:integrationStart+L-1, i);
        thisQ = qsignal(integrationStart:integrationStart+L-1, i);

        % transform I and Q to a frame rotating at IFfreq
        Iframe = zeros(1,L);
        Qframe = zeros(1,L);
        for j = 1:L
            ti = (j-1)*sampInterval;
            R = [cos(2*pi*IFfreq*ti) sin(2*pi*IFfreq*ti); -sin(2*pi*IFfreq*ti) cos(2*pi*IFfreq*ti)];
            temp = R * [thisI(j); thisQ(j)];
            Iframe(j) = temp(1);
            Qframe(j) = temp(2);
        end
        % find the DC components

        DI(i) = mean(Iframe);
        DQ(i) = mean(Qframe);
    end
end
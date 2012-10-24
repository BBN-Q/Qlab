%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Copyright 2010 Raytheon BBN Technologies
 %
 % Licensed under the Apache License, Version 2.0 (the "License");
 % you may not use this file except in compliance with the License.
 % You may obtain a copy of the License at
 %
 %     http://www.apache.org/licenses/LICENSE-2.0
 %
 % Unless required by applicable law or agreed to in writing, software
 % distributed under the License is distributed on an "AS IS" BASIS,
 % WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 % See the License for the specific language governing permissions and
 % limitations under the License.
 %
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

function [DI DQ] =  digitalHomodyneIQ(isignal, qsignal, IFfreq, sampInterval, integrationStart, integrationWindow)
    % first define a variable that takes the total length of the signal
    if nargin < 6
        L = length(isignal);
		integrationStart = 1;
    else
        L = integrationWindow;
    end
    
    % truncate the I and Q signals to the integration window
    thisI = isignal(integrationStart:integrationStart+L-1);
    thisQ = qsignal(integrationStart:integrationStart+L-1);

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

    DI = mean(Iframe);
    DQ = mean(Qframe);
end
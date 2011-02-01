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

function [DI DQ] =  digitalHomodyne(signal, IFfreq, sampInterval, integrationStart, integrationWindow)
    % first define a variable that takes the total length of the signal
    if nargin < 5
        L = length(signal);
		integrationStart = 1;
    else
        L = integrationWindow;
    end
    truncatesignal = signal(integrationStart:integrationStart+L-1);
    % define a time array with the same length as the signal but spaced at the
    % sampling time
    time = (0:L-1)*sampInterval;
    % define both a Sin and a Cos at the IFfreq with length L
    COS = cos(2*pi*time*IFfreq);
    SIN = sin(2*pi*time*IFfreq);
    % perform the discrete sum to obtain the digital I and digital Q signal
    DI = (2/L)*sum(COS*truncatesignal);
    DQ = (2/L)*sum(SIN*truncatesignal);
end
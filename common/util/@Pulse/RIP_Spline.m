function [outx, outy, framechange] = RIP_Spline(params)
% Generate a spline envelope for RIP pulses
% delta should have the pulse detuning Delta... 
assert(mod(params.width,2)==0);
midpoint = (params.width)/2;
t = 1:midpoint;
x1=0;
x2=midpoint;
y2 = 1;
y1=0;
framechange=0;
% Talk to Jay, Andrew, about WTF these came from.
y = (70*t.^6*(x1 + x2)*(y1 - y2))/(x1 - x2)^7 + ( ...
    210*t.^2*x1^2*x2^2*(x1 + x2)*(y1 - y2))/(x1 - x2)^7 - ( ...
    84*t.^5*(x1^2 + 3*x1*x2 + x2^2)*(y1 - y2))/(x1 - x2)^7 - ( ...
    140*t.^3*x1*x2*(x1^2 + 3*x1*x2 + x2^2)*(y1 - y2))/(x1 - x2)^7 + ( ...
    35*t.^4*(x1 + x2)*(x1^2 + 8*x1*x2 + x2^2)*(y1 - y2))/(x1 - x2)^7 + ( ...
    20*t.^7*(-y1 + y2))/(x1 - x2)^7 + ( ...
    140*t*x1^3*x2^3*(-y1 + y2))/(x1 - ...
    x2)^7 + (-x2^4*(-35*x1^3 + 21*x1^2*x2 - 7*x1*x2^2 + x2^3)*y1 + ...
    x1^4*(x1^3 - 7*x1^2*x2 + 21*x1*x2^2 - 35*x2^3)*y2)/(x1 - x2)^7;
  timeStep = 1/params.samplingRate;
modAngles = - 2*pi*1e9*params.delta*timeStep*(1:params.width);

% Use SSB modulation to shift RIP pulse away from cavity.  
% Using this approach allows different RIP gate combinations to have
% different detunings.
tmp=params.amp * ([y, fliplr(y)]');
outx = tmp .* cos(modAngles');
outy = tmp .* sin(modAngles');
if ~isfield(params,'noround')
 outx=round(outx);
 outy=round(outy);
end
    
%figure(1);
%plot(1:params.width,outx);
%drawnow;
end
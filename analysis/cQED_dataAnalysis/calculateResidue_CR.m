function [residue,x,y,z] = calculateResidue_CR(params,t,rvec)
%Rabi oscillations along an arbitrary axis

rx        = params(1); % Rabi frequency along x
ry        = params(2); % Rabi frequency along y
delta     = params(3); % detuning
x0        = params(4); % initial x
y0        = params(5); %initial y
z0        = params(6); % initial z

t=reshape(t,length(t),1);
omega = sqrt(rx^2+ry^2+delta^2);
x = (rx*delta*(-z0+x0*rx+y0*ry)+(rx*(z0*delta-y0*ry)+x0*(delta^2+ry^2)).*cos(t*omega)+omega*(y0*delta+z0*ry).*sin(t*omega))/omega^2;
y = (ry*delta*(-z0+x0*rx+y0*ry)+(ry*(z0*delta-x0*rx)+y0*(delta^2+rx^2)).*cos(t*omega)-omega*(x0*delta+z0*rx).*sin(t*omega))/omega^2;
z = (delta*(z0*delta-x0*rx-y0*ry)+(x0*delta*rx+y0*delta*ry+z0*(rx^2+ry^2)).*cos(t*omega)+omega*(y0*rx-x0*ry).*sin(omega*t))/omega^2;

rmodel = [x,y,z];

diffvec = rvec-rmodel;
residue = sum((diffvec(:)).^2)/(length(t)*3);

end
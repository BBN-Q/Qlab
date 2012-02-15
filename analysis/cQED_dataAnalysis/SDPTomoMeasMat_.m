function choi_SDP2 = SDPTomoMeasMat_(measmat,measurementoperators,U_preps,U_meas, pauliopts, numberofqubits,verbose)
% Jay Gambetta and Seth Merkel, Jan 20th 2012
% 
% this function perfomrs semi definte programing to find the closes physical map in the choi represenation to the data. It uses yalmip and sudumi
% Input
%	measmat = the measurement mat of the measurement opterators
%   measurementopts= the set of measurement opts for each calibrations 
%   U_preps = the set of preperation unitaries 
%   U_meas = the set of measurement unitaries 
%   pauliopts = a cell of all the pauli operators
%   numberofqubits = the number of qubits
% Return
%	choi_SDP2 = the corrected physical state
if nargin < 7
    verbose =0;
end



yalmip('clear')
d = 2^numberofqubits;
d2 = 4^numberofqubits;
d4 = 16^numberofqubits;
%xvec = sdpvar(d4-d2,1,'full','real');
xvec = sdpvar(d4,1,'full','real');
t=sdpvar(1,1,'full','real');

% the pauli decomposition of the state (not the confusing ordering as the
% identity is last)
choi_SDP=zeros(d2);

for ii =1:d2
    for jj=1:d2
        choi_SDP=choi_SDP+xvec((jj-1)*(d2)+ii)*kron(pauliopts{ii},pauliopts{jj})/d2;
    end
end
numberofmeasurements = size(measmat,1);
numberofpreps = size(measmat,2);

% different prepartions
psiin = zeros(d,1);
psiin(1,1)=1;
rhoin=Psi2Rho_(psiin);

for jj=1:length(U_preps)
    rho_preps{jj}=U_preps{jj}*rhoin*U_preps{jj}';
    for kk = 1:length(U_meas)
        measurementoptsset{jj}{kk}= U_meas{kk}'*measurementoperators{jj}*U_meas{kk};
    end
end

Matrix = zeros(numberofmeasurements*numberofpreps,d2*d2);

for ii =1:d2
   
    for jj=1:d2
        for ll=1:numberofpreps
            shittemp = trace(rho_preps{ll}.'*pauliopts{ii});
            for mm=1:numberofmeasurements
                shittemp2 =trace(pauliopts{jj}*measurementoptsset{ll}{mm});
                shittemp3 =shittemp*shittemp2/d;
                Matrix((mm-1)*numberofpreps+ll,(jj-1)*(d2)+ii)=-real(shittemp3);
            end
        end
    end
end



mtilde= reshape(measmat, numberofmeasurements*numberofpreps,1);
meas_trace = mtilde.'*mtilde;

newvariable = sqrtm(Matrix.'*Matrix);

Z = zeros(d2*d2+1,d2*d2+1);
temp = zeros(d2*d2+1,d2*d2+1);
temp(1,1) = 1;
%The Z Matrix
%slack variable
Z =Z + t*temp;


Z(2:end,1) = newvariable*xvec;
Z(1,2:end) = xvec.'*newvariable.';
Z(2:end,2:end) = eye(d2*d2);

%Z(2:end,2:end) = inv(Matrix'*Matrix);

constraints = [Z>0, choi_SDP>0];


obj =  meas_trace + mtilde.'*Matrix*xvec + xvec.'*Matrix.'*mtilde + t;


solvesdp(set(constraints),obj,sdpsettings('verbose',verbose));

xvecd = double(xvec);

choi_SDP2=zeros(d2);
for ii =1:d2
    for jj=1:d2
        choi_SDP2=choi_SDP2+xvecd((jj-1)*(d2)+ii)*kron(pauliopts{ii},pauliopts{jj})/d2;
    end
end


end

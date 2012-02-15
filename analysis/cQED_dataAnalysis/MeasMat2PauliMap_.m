function [pauliMap] = MeasMat2PauliMap_(meas_matrix, measurementoperators,U_preps,U_meas, pauliopts,numberofqubits)
% Jay Gambetta and Seth Merkel, Jan 20th 2012
% 
% takes in a measurment matrix and makes a chi matrix
% Input 
%	measmat = the measurement mat of the measurement opterators
%   measurementopts= the set of measurement opts for each calibrations 
%   U_preps = the set of preperation unitaries 
%   U_meas = the set of measurement unitaries 
%	pauliopts = a cell of dim 4^n containing the pauliopts
%	numberofqubtis = number of qubits
%Output
% the chi matrix

d=2^numberofqubits;
numberofmeasurements = length(U_meas);
numberofpreps = length(U_preps);


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


Matrix = zeros(numberofmeasurements*numberofpreps,d^2*d^2);

for ii =1:d^2
    for jj=1:d^2
        for ll=1:numberofpreps
            shittemp = trace(rho_preps{ll}*pauliopts{jj});
            for mm=1:numberofmeasurements
                shittemp2 =trace(pauliopts{ii}*measurementoptsset{ll}{mm});
                shittemp3 =shittemp*shittemp2/d;
                Matrix((mm-1)*numberofpreps+ll,(jj-1)*(d^2)+ii)=real(shittemp3);
            end
        end
    end
end

measvec = reshape(meas_matrix, numberofmeasurements*numberofpreps,1);

pauliMap = reshape((inv(transpose(Matrix)*Matrix)*transpose(Matrix)*measvec),d^2,d^2);

end
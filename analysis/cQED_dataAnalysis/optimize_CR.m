function optimize_CR(choiMeas, Uideal)

%Helper function to optimize the CR gate with local rotations
X = [0, 1;1 0]; Y = [0 -1i;1i 0]; Z = [1 0;0 -1];

tmp = PauliOperators_(2);
paulis = tmp.opt;
paulistrings = tmp.string;

chiMeas = Choi2Chi_(choiMeas, paulis, 2);

% %%First let's try single-qubit Z rotations
    function error = fitFunc(thetas)
        %Modify Uideal by the Z rotations
        Zrot1 = expm(-1i*thetas(1)/2*Z);
        Zrot2 = expm(-1i*thetas(2)/2*Z);
        rotatedU = kron(Zrot1,Zrot2)*Uideal;
        choiRotated = Unitary2Choi_(rotatedU);
        chiRotated = Choi2Chi_(choiRotated, paulis, 2);
        processFidelity = real(trace(chiRotated*chiMeas));
        gateFidelity = (2^2*processFidelity+1)/(2^2+1);
        error = 1-gateFidelity;
    end

%Optimize the rotations
bestThetas = fminsearch(@fitFunc, [0,0])

% %%Generic rotations
%     function error = fitFunc(thetas)
%         %Modify Uideal by the Z rotations
%         rot1 = expm(-1i*thetas(3)/2*Z)*expm(-1i*thetas(2)/2*X)*expm(-1i*thetas(1)/2*Z);
%         rot2 = expm(-1i*thetas(6)/2*Z)*expm(-1i*thetas(5)/2*X)*expm(-1i*thetas(4)/2*Z);
%         rotatedU = kron(rot1,rot2)*Uideal;
%         choiRotated = Unitary2Choi_(rotatedU);
%         chiRotated = Choi2Chi_(choiRotated, paulis, 2);
%         processFidelity = real(trace(chiRotated*chiMeas));
%         gateFidelity = (2^2*processFidelity+1)/(2^2+1);
%         error = 1-gateFidelity;
%     end
% 
% %Optimize the rotations
% bestThetas = fminsearch(@fitFunc, zeros(1,6))

bestError = fitFunc(bestThetas)

Zcorrection1 = expm(1i*bestThetas(1)/2*Z);
Zcorrection2 = expm(1i*bestThetas(2)/2*Z);
UCorrection = kron(Zcorrection1, Zcorrection2);
choiCorrection = Unitary2Choi_(UCorrection);

correctedPauliMap = Choi2PauliMap_(choiCorrection)*Choi2PauliMap_(choiMeas);

cmap = [hot(50); 1-hot(50)];
cmap = cmap(19:19+63,:); % make a 64-entry colormap


figure()
imagesc(real(correctedPauliMap),[-1,1])
colormap(cmap)
colorbar

set(gca, 'XTick', 1:4^2);
set(gca, 'XTickLabel', paulistrings);

set(gca, 'YTick', 1:4^2);
set(gca, 'YTickLabel', paulistrings);
xlabel('Input Pauli Operator', 'FontSize', 12);
ylabel('Output Pauli Operator', 'FontSize', 12);
title('Pauli Map Constrained Process Tomography','FontSize',14);




end
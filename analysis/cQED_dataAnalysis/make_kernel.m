function [gavg,eavg] = make_kernel(filename,qubit,varargin)
%inputs: a) filename of saved average traces for qubit in |0> and |1>
% b) qubit string defining the file name for the kernel

data = read_records(filename);
gdata = squeeze(data(:,1,1:2:end));
edata = squeeze(data(:,1,2:2:end));
gavg = mean(gdata,2);
eavg = mean(edata,2);
mykernel = (eavg - gavg);
mykernel = mykernel/sum(abs(mykernel));

if(nargin>2)
    kerlength = varargin{1};
else
    kerlength = length(mykernel)-2;
end
mykernel = mykernel(1:kerlength);
dlmwrite(strcat('kernel_',qubit,'_real.csv'), real(mykernel))
dlmwrite(strcat('kernel_',qubit,'_imag.csv'), imag(mykernel))

end

% in PyQlab settings use something like:
% np.loadtxt('C:\Users\qlab\Documents\MATLAB\kernel_real.csv') + 1j*np.loadtxt('C:\Users\qlab\Documents\MATLAB\kernel_imag.csv')

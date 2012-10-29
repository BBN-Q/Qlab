function rhoWizard = WizardTomo_(rhoRAW, num)
% Jay Gambetta and John Smolin 
%this function allpies Wizard tomography to the state matrix of num qubits 
    
    jerrydogyfactor = trace(rhoRAW);
    rhoRAW=rhoRAW/jerrydogyfactor;
    rhoWizard=  zeros(2^num,2^num);  
    [u,v]=eig(rhoRAW);
    [v order] = sort(diag(v),'ascend');  %# sort eigenvalues in descending order
    u = u(:,order);
    for jj=1:2^num-1
        if v(jj) < 1e-9
            temp=v(jj);
            v(jj)=0;
            for kk =jj+1:2^num
                v(kk)=v(kk)+temp/(2^num-jj);
            end
        end
    end
    for jj=1:2^num
        rhoWizard=rhoWizard + u(:,jj)*u(:,jj)'*v(jj);
    end
end

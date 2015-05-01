function successvec = LPN(data, ndataqubits, codeID, LPNq, maxqueries, nrandom)
%codeID = 1...2^ndataqubits. ID for the implemented oracle
%LPNq = 1 if quantum protocols, 0 if classical
%maxqueries = max. number of queries analyzed
%nrandom = number of random subsets of data for each number of queries

signvec = ones(ndataqubits+1,1); %A, Q1, Q2... Assumes that M=0 for M>Mthr.  
doDig = 0; %if 1 (and LPNq=1), single shots are digitized before a majority vote. If 0, shot voltages are first averaged, then the average is digitized. 

[codemat, resultvec, thrvec] = digitizeShots(data,LPNq,ndataqubits,doDig,signvec);

nshots = size(codemat,1);
successvec = zeros(maxqueries,1);
xmat = dec2bin(0:2^ndataqubits-1, ndataqubits);
distance = zeros(2^size(codemat,2),1);

for nvotes=1:maxqueries
    yvec=zeros(nvotes,1);

    for jj=1:nrandom
        
        samplemat = nan(nvotes,size(codemat,2));
        randvec = randi([1,nshots],nvotes,1);

        for k=1:nvotes
            samplemat(k,:) = codemat(randvec(k),:);
            if LPNq==0
               yvec(k) = resultvec(randvec(k)); 
            end
        end
        
        if LPNq==1
            if(doDig==0)
                samplemat = nanmean(samplemat,1);
                for kk = 1:ndataqubits
                    samplemat(1,kk) = -0.5*(signvec(1+kk)-1)*(samplemat(1,kk)>=thrvec(1+kk)) + 0.5*(signvec(1+kk)+1)*(samplemat(1,kk)<thrvec(1+kk));
                end
                majvote = samplemat;
            else
                majvote = mode(samplemat);
            end
            if majvote == str2num(reshape(xmat(codeID,:)',[],1))'; 
                successvec(nvotes)=successvec(nvotes)+1;
            end
        else
            for t=1:size(xmat,1)
                xtest = str2num(reshape(xmat(t,:)',[],1))';
                distance(t) = sum(abs(mod(samplemat*xtest'-yvec,2)));
            end
            [~,indmin]=min(distance);
            if indmin==codeID 
                successvec(nvotes)=successvec(nvotes)+1;
            end
            
        end        
    end
end
successvec=successvec/nrandom;

figure(202); 
plot(successvec); ylim([0,1]); 
        
    


    
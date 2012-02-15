function [ Lambda ] = Choi2Liouville_( Choi, d)
%this function returns the Liouville matrix for a Choi representation of a
%map 

Lambda = d*Choi;

for n=1:d,
    for m=1:d,
        for j=1:d,
            for k=n+1:d,
                temp = Lambda( (n-1)*d+m, (j-1)*d+k );
                Lambda( (n-1)*d+m, (j-1)*d+k ) = Lambda( (k-1)*d+m, (j-1)*d+n );
                Lambda( (k-1)*d+m, (j-1)*d+n) = temp;
            end
        end
    end
end


end


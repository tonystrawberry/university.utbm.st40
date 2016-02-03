function Z = orzGSO(X, nNum)
% conventional Gram Schmidt Orthogonalization ver.1.00 by igarashi

nDim = size(X,1);
if(nargin < 2)
    nNum = rank(X);
    Z = zeros(nDim, nNum);
else
    Z = zeros(nDim, nNum);
end

Z(:,1) = X(:,1)./ norm(X(:,1));

for I=2:nNum;
    V = X(:,I);
    for J=1:I-1;
        V = V - (Z(:,J)'*X(:,I))*Z(:,J);
    end;
    Z(:,I) = V ./ norm(V);
end;
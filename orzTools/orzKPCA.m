function [A,D,K] = orzKPCA(X,Y,nSigma,varargin)
	% ƒJ?[ƒlƒ‹Žå?¬•ª•ª?Í ver.1.00 by ohkawa
	% input
	%  X: input matrix
	%  Y: dimension of subspaces
	%  nSigma: gaussian kernel parameter

	% output
	%  A: basis vectors KPCA
	%  D: eigenvalue
	%  K: kernel matrix


	X = X(:,:);
	[nDim,nNum] =size(X);

	flgM = true;
	if nargin == 4
		if varargin{1} == 'R'
			flgM = false;
		end
	end

	K=exp(-orzL2Distance(X,X)/nSigma);

	if flgM==true % covariance matrix
		IN =  ones(nNum,nNum)/nNum;
		K = K - IN*K - K*IN + IN*K*IN;
	end

    nSubDim = floor(Y);
    OPTS.disp = 0;
%     [A B] = eigs(K,nSubDim,'lm',OPTS);  %[A B] = eigs(K,nSubDim);
    [A B] = eig(K);  %[A B] = eigs(K,nSubDim);
    [B ind] = sort(diag(B),'descend');
    A=A(:,ind);
    A = A(:,1:nSubDim);
    B = B(1:nSubDim);
    D = B/nNum;
    A = A/sqrt(diag(B));
    C = sum(D);
end

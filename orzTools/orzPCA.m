function [Z,U,D,E] = orzPCA(X,Y,varargin)
%function [Z,U,D,E] = orzPCA(X,Y,varargin)
% 主?ｬ分分?ﾍ ver.1.00 by ohkawa
% input
%  X: 入力マトリックス input matrix
%  Y: 部分空間の次元もしくは寄与率 
%  Yが1.0以下ならば?C Yは寄与率と判断
%  Yが1.0超過ならば?C Yは部分空間の次元と判断
%  第三引??EFデフォルトでは?C共分散 covariance ?s列のPCA
%  第三引?狽ｪ'R'の時?C自己相関?s列のPCA
%  
%?@nDim< nNumの時は通?墲ﾌPCA
%  nDim>=nNumのときは??E`カ?[ネルPCA?i双対問題?jを適用する
% output
%  Z: 主?ｬ分空間に射影されたデ?[タ projection
%  U: 主?ｬ分ベクトル basis vector
%  D: 固有値 eigenvalue
%  E: 寄与率 ratio


X = X(:,:);
[nDim,nNum] = size(X);

flgM = true;
if nargin == 3
    if varargin{1} == 'R'
        flgM = false;
    end
end

if Y <= 1 % 寄与率
    cRate = Y;
    if nDim<nNum
        if flgM==true
            C = cov(X',1);
        else
            C = X*X'/nNum;
        end
        [U,tmpD]= eig(C);
        [D ind]= sort(diag(tmpD),'descend');
        U = U(:,ind);
        nSubDim = find(cumsum(D)/sum(D)>=cRate, 1 );
        U=U(:,1:nSubDim);
        D = D(1:nSubDim);
        E = sum(D)/trace(C);
    else
        if flgM==true
            K = X'*X;
            IN =  ones(nNum,nNum)/nNum;
            K = K - IN*K - K*IN + IN*K*IN;
        else
            K = X'*X;
        end
        [A B] = eig(K);
        [B ind] = sort(diag(B),'descend');
        A=A(:,ind);
        D = B/nNum;
        nSubDim = find(cumsum(D)/sum(D)>=cRate, 1 );
        A=A(:,1:nSubDim);
        B=B(1:nSubDim);
        A = A/sqrt(diag(B));
        U = X*A;
        D = D(1:nSubDim);
        E = sum(D);        
    end
elseif Y > 1 % 主?ｬ分空間の次元
    nSubDim = floor(Y);
    if nDim<nNum
        if flgM==true % 共分散?s列
            C = cov(X',1);
        else % 自己相関?s列
            C = X*X'/nNum;
        end
        
        OPTS.disp = 0;
        if nSubDim<nDim 
           [U tmpD] = eigs(C,nSubDim,'lm',OPTS); %[U,tmpD]= eigs(C,nSubDim);
        else
           [U tmpD] = eig(C);
        end
        [D ind]= sort(diag(tmpD),'descend');
        U = U(:,ind);
        E = sum(D)/trace(C);
    else %カ?[ネル
        if flgM==true % 共分散?s列
            K = X'*X;
            IN =  ones(nNum,nNum)/nNum;
            K = K - IN*K - K*IN + IN*K*IN;
        else  % 自己相関?s列
            X = double(X);
            K = transpose(X)*X;
        end
        OPTS.disp = 0;    
        [testvec testval] = eig(K);
        [A B] = eigs(K,nSubDim,'lm',OPTS);
        [B ind] = sort(diag(B),'descend');
        A = A(:,ind);
        D = B/nNum;
        A = A/sqrt(diag(B));
        U = X*A;
        E = sum(D);
    end
end
Z = U'*X;
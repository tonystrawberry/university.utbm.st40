classdef OrzKOMSMV2
    properties (SetAccess = public)
        nDim;
        nNum1;
        nClass;
        nSubDim1;
        nOrthDim;
        nSigma;
                
        nAlpha;
        nBeta;
        
        X1;
        A1;
        E1;
        C1;
        
        D;
        O;
        W;
    end% properties
    
    methods
        function OB = OrzKOMSMV2(X1, nSubDim1, nSigma, varargin)
%function OB = OrzKOMSM(X1, nSubDim1,nSigma, varargin)
% nDim:     dimension
% nNum1:    data of each class
% nClass:   class number
% nSubDim1: dimension of subspace KPCA
% nOrthDim: dimension of orthogonalized subspace 
% nSigma:   gaussian kernel parameter

          
% X1:       original data
% A1:       basis vectors of XI after KPCA
% E1:       eigenvalue
            
% D:        orthogonalization matrix
% O:        kernel orthogonalization matrix
% W:        eigenvalue of D



      
            if nargin == 3
                OB.nAlpha = 1;
                OB.nBeta  = 0;
            elseif nargin == 4
                OB.nAlpha = varargin{1};
                OB.nBeta  = 0;                
            elseif nargin == 5
                OB.nAlpha = varargin{1};
                OB.nBeta  = varargin{2};                
            end
            
            OB.nSubDim1 = nSubDim1; % dimension of the final reference subspaces
            OB.nSigma = nSigma; % sigma parameter of the kernel function
            OB.X1 = X1; % image vectors of non-linear subspace     
            
            OB.nClass = size(X1, 2); % number of classes (or different faces)

            OB.A1 = {}; % basis vectors
            OB.E1 = zeros(OB.nSubDim1,OB.nClass); % eigenvalues

            for I=1:OB.nClass                
                [OB.A1{I}, OB.E1(:,I)] = orzKPCA(OB.X1{I},OB.nSubDim1,OB.nSigma,'R');
            end
          
            OB.D = zeros(OB.nSubDim1, OB.nSubDim1, OB.nClass,OB.nClass); % kernel matrix
            for I1 = 1:OB.nClass
                for I2 = I1:OB.nClass
                    K = exp(-orzL2Distance(X1{I1}, X1{I2})/nSigma);
                    if I1 == I2
                        OB.D(:,:,I1,I2) = eye(OB.nSubDim1,OB.nSubDim1);
                    else
                        OB.D(:,:,I1,I2) =  OB.A1{I1}'*K* OB.A1{I2};
                        OB.D(:,:,I2,I1) = OB.D(:,:,I1,I2)';
                    end
                end
            end
            
            OB.D = reshape(permute(OB.D,[1,3,2,4]), OB.nSubDim1 * OB.nClass, OB.nSubDim1 * OB.nClass);
            
            [B,OB.W] = eig(OB.D); % get eigenvector and eigenvalue            
            OB.W = diag(OB.W/trace(OB.W)); % normalization
            [OB.W, ind] = sort(OB.W,'descend'); % sort by descending order
            B = B(:,ind);
            OB.nOrthDim = find(cumsum(OB.W)/sum(OB.W)>=OB.nAlpha, 1 ); 
            B = B(:,1:OB.nOrthDim);
            OB.W = OB.W(1:OB.nOrthDim); 
                    
            OB.O = diag(1./(OB.W+OB.nBeta))*B'; % whitening matrix

        end
        function [V2 A2] = TransformS(OB, X2,nSubDim2)
			% Orthogonal transformation for the subspace
			% KPCA then orthogonal transformation then Gram-Schmidt Matrix

            nSize = size(X2,2);

            nSet2 = size(X2, 2);
            
            A2 = {};
            E2 = zeros(nSubDim2,nSet2);
            for I=1:nSet2
                [A2{I} E2(:,I)] = orzKPCA(X2{I},nSubDim2,OB.nSigma,'R');
            end
            
            V2 = zeros(OB.nOrthDim,nSubDim2,nSet2);
            for J = 1:nSet2
                nNum2 = size(X2{J},2);
                a = zeros( OB.nSubDim1, nNum2,OB.nClass);
                for I = 1:OB.nClass
                    Z = exp(-orzL2Distance(OB.X1{I},X2{J})/OB.nSigma);                    
                    a(:,:,I) = OB.A1{I}' * Z;
                end
                a = permute(a,[1,3,2]);
                a = reshape(a,size(a,1)*size(a,2),size(a,3));
                V2(:,:,J) = orzGSO(OB.O*a*A2{J}); % gram-schmidt orthogonalization
            end
            V2 = reshape(V2,[OB.nOrthDim,nSubDim2,nSize,1]); % basis orthogonalized vectors
            
        end
        
       
        
    end
end

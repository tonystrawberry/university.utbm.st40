function Y = orzNormalize(X, varargin)
% Y = orzNormalize(X)
% input
%  X: column vectors
% output
%  Y: normalized vectors
% 
X = double(X);

if nargin < 1
    error('error');
end

if nargin == 1
    D = 2;    
    A = sum(abs(X).^D).^(1/D); % norm of vector
    
    % Case where norm = 0
    [s, I] = find(A==0);
    A(I) = 1;
    
    Y = X./repmat(A,size(X,1),1);
    
elseif nargin == 2
    
    D = varargin{1};
    if D==0;
       error('error');
    end
    A = sum(abs(X).^D).^(1/D);
    [s, I] = find(A==0);
    A(I) = 1;
    Y = X./repmat(A,size(X,1),1);
else
    error('error');
end


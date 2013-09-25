% Runs Orthogonal k-means (ok-means) on the dataset X (n p-dimensional
% data points) and generates m hyperplanes. As a result 2^m centers
% can be represented.

function [model, B] = okmeans(X, m, niter)

% Inputs:
%       X: p*n -- n p-dimensional input points used for training the quantizer.
%       m: number of binary bits in the encoding.
%       niter: number of iterations for the iterative optimization.

% Outputs:
%       model: the learned quantization model and its parameters.
%       B: m*n -- n m-bit binary codes.

% obj: the quantization error objective.
obj = Inf;

model.type = 'okmeans';
n = size(X, 2);
p = size(X, 1);
model.m = m;
model.p = p;

% initialize mu
mu = mean(X, 2);
X_mu = bsxfun(@minus, X, mu);

% initialize R with a random rotation of m-dim PCA subspace
C = cov(double(X_mu'));
[R, S, V] = svd(randn(m, m));
if (p > m)
  [pc, l] = eigs(C, m);
  R = pc * R;  % It is going to be p * m
end
model.initR = single(R);

for (iter = 0:niter)        % niter+1 iterations
  RX = R' * X_mu;

  % update B and D
  B = sign(RX);
  d = mean(abs(RX), 2);       % the diagonal of matrix D
  DB = bsxfun(@times, d, B);  % the product D * B

  % update R
  [U, S, V] = svd(X_mu * DB', 0);
  R = U * V';
  clear U S V;

  RDB = R * DB;
  % update mu
  mu = mean(X - RDB, 2);
  X_mu = bsxfun(@minus, X, mu);
  
  if (mod(iter, 10) == 0)
    objlast = obj;
    tmp = RDB - X_mu;
    tmp = tmp.^2;
    obj = mean(sum(tmp, 'double'));
    fprintf('%3d %.4f   \n', iter, obj);  
    model.obj(iter+1) = obj;
  else
    fprintf('%3d\r', iter);
  end
  
  if (objlast - obj < 1e-5)
    fprintf('not enough improvement in the objective... breaking.\n')
    iter=niter;
  end  
end

model.mu = mu;
model.d = d;
model.R = R;

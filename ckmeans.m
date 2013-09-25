% Runs Cartesian k-means (ck-means) on the dataset X (n p-dimensional
% data points) and generates m subspaces with h centers in each. As a
% result a total of h^m centers can be represented.

function [model, B] = ckmeans(X, m, h, niter, init)

% Inputs:
%       X: p*n -- n p-dimensional input points used for training the quantizer.
%       m: number of subspaces in the encoding.
%       h: number of centers per subspace.
%          if h is an m-dim array, h(i) is the number of centers in
%          the i-th subspace
%       niter: number of iterations for the iterative optimization.
%       init: a flag to determine how to initialize the rotation matrix

% Outputs:
%       model: the learned quantization model and its parameters.
%       B: the en

% obj: the quantization error objective.
obj = Inf;

model.type = 'ckmeans';
n = size(X, 2);
p = size(X, 1);
model.m = m;
model.p = p;

if (length(h) == 1)
  h = ones(m, 1) * h;
end
nbits = sum(log2(h));
model.h = h;
model.nbits = nbits;

% len: an m-dim array the i-th element of which, i.e. len(i), stores
%      the dimensionality of the i-th subspace.
len = ones(m, 1) * floor(p / m);
len(1:mod(p, m)) = len(1:mod(p, m)) + 1;  % p = m * floor(p / m) + mod(p, m)
model.len = len;

len0 = 1 + cumsum([0; len(1:end-1)]);
len1 = cumsum(len);

DB = zeros(size(X), 'single');  % DB stores D*B

if (strcmp(init, 'natural'))
  % initialize R by identity matrix
  R = eye(p, p, 'single'); % Default
elseif (strcmp(init, 'random'))
  % initialize R by random rotation
  [R, S, V] = svd(randn(p, p));
elseif (strcmp(init, 'distribute'))
  step = m;
  if (gcd(p - 1, step) > 1)
    error('gcd(p - 1, step) > 1');
  end
  a = 0:step:(p * step - 1);
  a = mod(a, p - 1);
  a(1 + find(a(2:end) == 0)) = p - 1;
  a = a + 1;
  R = eye(p, p, 'single'); % Default
  R = R(a, :)';
end
R = single(R);
model.init = init;
model.initR = R;

RX = R' * X;

% initialize D
D = cell(m, 1);

% inializing D by random selection of subspace centers (after rotation).
for (i=1:m)
  perm = randperm(n, h(i));
  D{i} = RX(len0(i):len1(i), perm);
end

% initialize B
B = zeros(n, m, 'int32');
for (i=1:m)
  B(:, i) = euc_nn_mex(D{i}, RX(len0(i):len1(i), :));
  DB(len0(i):len1(i), :) = D{i}(:, B(:, i));
end

for (iter=0:niter)
  if (mod(iter, 10) == 0)
    objlast = obj;
    tmp = R * DB;
    tmp = tmp - X;
    tmp = tmp.^2;
    obj = mean(sum(tmp, 'double'));
    clear tmp;
    fprintf('%3d %.4f   \n', iter, obj);  
    model.obj(iter+1) = obj;
  else
    fprintf('%3d\r', iter);
  end
  
  if (objlast - obj < model.obj(1) * 1e-5)
    fprintf('not enough improvement in the objective... breaking.\n')
    break;
  end
  
  % update R
  [U, S, V] = svd(X * DB', 0);
  R = U * V';
  clear U S V;
  
  % update R*X
  RX = R' * X;
  
  for (i=1:m)
    % update D
    D{i} = kmeans_iter_mex(RX(len0(i):len1(i), :), B(:, i), h(i));
    % update B
    B(:, i) = euc_nn_mex(D{i}, RX(len0(i):len1(i), :));
    % TODO: remove [B(:, i) b] = yael_nn(D{i}, RX(len0(i):len1(i), :), 1, 2);
    % update D*B
    DB(len0(i):len1(i), :) = D{i}(:, B(:, i));
  end
end

for (i=1:m)
  model.centers{i} = D{i};
end
model.R = R;

B = B';

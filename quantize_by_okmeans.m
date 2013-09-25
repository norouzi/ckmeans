function [Q, RX] = quantize_by_okmeans(X, model)

% Inputs:
%       X: p*n -- n p-dimensional input points to be quantized.
%       model: a model created by okmeans function -- it should contain: mu, R

% Outputs:
%       Q: (m/8)*n -- n m-bit binary codes as encoding of X
%          represented in compressed from by compactbit.
%       RX: m*n -- transformation of the data-points into a space
%           in which taking sign gives us the binary codes

X_mu = bsxfun(@minus, X, model.mu);
RX = model.R' * X_mu;
Q = compactbit(sign(RX) > 0);

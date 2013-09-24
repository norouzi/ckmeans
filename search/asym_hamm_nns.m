% Running k-nearest neighbor search according to Asymmetric Hamming distance

function [ind sqrdis] = asym_hamm_nns(B, C, d, knn)

% Inputs:
%       B: (m/8)*n -- n m-bit codes represented in compressed format,
%          created by compactbit. Every 8 bits is represented by a unit8.
%       C: m*n -- n m-dim data points that should be compared with the 
%          binary codes in B using Asymmetric Hamming (AH) distance.
%       d: m*1 -- m real numbers that determine the weight of each bit.
%       knn: scaler -- number of nearest neighbors to be found.

% Outputs:
%       ind: indices of nearest elements from B (one-based)
%       sqrdis: squared distances to the nearest neighbors


m = size(C, 1);
assert(m / 8 == size(B, 1), ['number of rows of B should be equal' ...
                             ' to 1/8 * number of rows of C.']);

if (numel(d) == 1)
  d = ones(m, 1) * d;
end

centers = zeros(8, 256, m / 8);
for k=0:(m / 8 - 1)
  for i=0:255
    s = dec2bin(i, 8);
    centers(:, i+1, k+1) = ...
        ((s(end:-1:1) == '0') .* -d(k * 8 + (8:-1:1))' + ...
         (s(end:-1:1) == '1') .* d(k * 8 + (8:-1:1))')';
  end
end
centers = double(centers);

[ind, sqrdis] = linscan_aqd_knn_mex(B, double(C), size(B, 2), ...
                                    size(B,1) * 8, knn, centers);

% Running k-nearest neighbor search according to Hamming distance

function [ind counter] = hamm_nns(B, C, knn)

% Inputs:
%       B: (m/8)*n -- n m-bit codes represented in compressed format,
%          created by compactbit. Every 8 bits is represented by a unit8.
%       C: (m/8)*n -- n m-bit query codes represented in compressed format
%          that should be compared with the binary codes in B using Hamming
%          distance.
%       knn: scaler -- number of nearest neighbors to be found.

% Outputs:
%       ind: indices of nearest elements from B (one-based)
%       counter: a count vector that counts how many of the k nearest
%                items have a hamming distance of 0, 1, ..., nbits


assert(size(C, 1) == size(B, 1), ['number of rows of B and C should' ...
                                  ' be equal.']);
n = size(B, 2);
m = size(B, 1) * 8;

[ind, counter] = linscan_hamm_knn_mex(B, C, n, m, knn);

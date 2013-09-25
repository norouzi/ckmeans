% Display statistics about the search
%
% This software is governed by the CeCILL license under French law and
% abiding by the rules of distribution of free software. 
% See http://www.cecill.info/licences.en.html
%
% This package was written by Herve Jegou
% Copyright (C) INRIA 2009-2011
% Last change: February 2011. 
%
% This file is modified by Mohammad Norouzi


function recall_at_i = test_compute_stats(ids_gnd, ids_predicted, k)

nquery = size(ids_predicted, 2);
assert(nquery == size(ids_gnd, 2), ['number of columns of ids_gnd is not ' ...
                                    'consistent with ids_predicted.']);
nn_ranks = zeros(nquery, 1);
hist_pqc = zeros(k+1, 1);
for i = 1:nquery
  gnd_ids = ids_gnd(i);
  
  nn_pos = find(ids_predicted(:, i) == gnd_ids);
  
  if length(nn_pos) == 1
    nn_ranks(i) = nn_pos;
  else
    nn_ranks(i) = k + 1; 
  end
end
nn_ranks = sort(nn_ranks);

for i = [1 2 5 10 20 50 100 200 500 1000 2000 5000 10000]
  if i <= k
    recall_at_i(i) = length(find(nn_ranks <= i & nn_ranks <= k)) / nquery * 100;
    fprintf('r@%3d = %.3f\n', i, recall_at_i(i)); 
  end
end

for i=1:k
  recall_at_i(i) = length(find(nn_ranks <= i & nn_ranks <= k)) / nquery * 100;
end

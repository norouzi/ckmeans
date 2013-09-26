function [DB RDB] = reconstruct_by_ckmeans(Q, model)

if (max(Q(:)) == max(model.h))
  error('Q should be zero-based.');
end

len0 = 1 + cumsum([0; model.len(1:end-1)]);
len1 = cumsum(model.len);
m = model.m;
n = size(Q, 2);

DB = zeros(sum(model.len), n);
for (i=1:m)
  DB(len0(i):len1(i), :) = model.centers{i}(:, 1 + uint16(Q(i, :)));
end

RDB = model.R * DB;

% Inputs:
%   trdata: training data.
%   dataset_name: name of the dataset.
%   model_type: can be any of 'itq', 'okmeans', 'ckmeans',
%               'okmeans0', 'ck-means0'.
%   nbits: number of bits to use for quantization

% Output:
%   model: trained model.

function model = train_model(trdata, dataset_name, model_type, nbits, ...
                             npca, niter)

subspace_bits = 8;  % We assume that each ckmeans' subspaces has 256
                    % centers. This assumption propagates through our
                    % quantization and search code too.
m_ckmeans = nbits / subspace_bits;
if (~exist('niter', 'var'))
  niter = 100;
end

% PCA dimensionality reduction as a pre-processing to speed-up
% training of the quantization methods. NOTE: if model_type is
% okmeans0 or ckmeans0 no PCA pre-processing is performed.

default_npca_ck = max(384, nbits * 2);
if (strcmp(model_type, 'okmeans') || ...
    strcmp(model_type, 'itq') || ...
    strcmp(model_type, 'ckmeans'))
  mu = mean(trdata, 2);
  if (strcmp(model_type, 'okmeans') || ...
    strcmp(model_type, 'itq'))
    if (~exist('npca', 'var'))
      npca = min(nbits, size(trdata, 1));
    end
  elseif (strcmp(model_type, 'ckmeans'))
    if (~exist('npca', 'var'))
      npca = min(default_npca_ck - mod(default_npca_ck, m_ckmeans), ...
                 size(trdata, 1) - mod(size(trdata, 1), m_ckmeans));
    end
  end
  if (strcmp(model_type, 'ckmeans0'))
    if (mod(size(trdata, 1), m_ckmeans) ~= 0)
      error('p (data-point dim) is not devisible by (nbits / subspace_bits)');
    end
  end

  if (npca == size(trdata, 1))
    pc = eye(size(trdata, 1));
  else
    [pc, l] = eigs(cov(double(bsxfun(@minus, trdata, mu)')), npca);
  end
  trdata2 = pc' * bsxfun(@minus, trdata, mu);
  fprintf('trdata2 created, size(trdata2) = (%d, %.1e).\n', ...
          size(trdata2, 1), size(trdata2, 2));
end

% Run the actual training of the models.

if (strcmp(model_type, 'ckmeans') || ...
    strcmp(model_type, 'ckmeans0'))
  if (strcmp(model_type, 'ckmeans0') || ...  % If no PCA.
      npca == size(trdata, 1))
    if (strcmp(dataset_name, 'sift_1M') || ...
        strcmp(dataset_name, 'sift_1B'))  % If consecutive
                                          % partitioning of the
                                          % dimensions makes sense.
      ckmeans_init = 'natural';
    else
      ckmeans_init = 'random';
    end
  else  % If PCA is applied.
    ckmeans_init = 'distribute';
  end
  fprintf('ckmeans init: "%s"\n', ckmeans_init);
end

if (strcmp(model_type, 'itq'))
  model = compressITQ(double(trdata2'), nbits, niter);
elseif (strcmp(model_type, 'okmeans'))
  model = okmeans(trdata2, nbits, niter);
elseif (strcmp(model_type, 'ckmeans'))
  model = ckmeans(trdata2, m_ckmeans, 2 ^ subspace_bits, niter, ckmeans_init);
elseif (strcmp(model_type, 'okmeans0'))  % No PCA
  model = okmeans(trdata, nbits, niter);
elseif (strcmp(model_type, 'ckmeans0'))  % No PCA
  model = ckmeans(trdata, m_ckmeans, 2 ^ subspace_bits, niter, ckmeans_init);
end

% Revert the effect of PCA dimensionality reduction. This is done to
% only keep the model around, and throw away pc and mu.

if (strcmp(model_type, 'okmeans') || ...
    strcmp(model_type, 'itq'))
  model.mu = pc * model.mu + mu;
  model.R = pc * model.R;
  model.preprocess.pc = pc;
  model.preprocess.mu = mu;
end
if (strcmp(model_type, 'ckmeans'))
  model.R = pc * model.R;
  Rmu = model.R' * mu;
  len0 = 1 + cumsum([0; model.len(1:end-1)]);
  len1 = cumsum(model.len);
  for (i = 1:model.m)
    % Add mu back
    model.centers{i} = bsxfun(@plus, model.centers{i}, Rmu(len0(i):len1(i)));
  end
  model.preprocess.pc = pc;
  model.preprocess.mu = mu;
end

% Where the datasets are located (you need to set this):
% the root of INIRA BIGANN datasets:
INRIA_HOME = 'WHERE_TEXMEX_INRIA_DATASETS_ARE_LOCATED';
% the root of 80 million tiny images dataset:
TINY_HOME = 'WHERE_80M_TINY_IMAGES_DATASET_IS_LOCATED';

if (~exist(INRIA_HOME, 'dir'))
  fprintf('"%s" is not a directory.\n', INRIA_HOME);
else
  addpath([INRIA_HOME, '/matlab']);
end
if (~exist(TINY_HOME, 'dir'))
  fprintf('"%s" is not a directory.\n', TINY_HOME);
else
  addpath([TINY_HOME, '/code']);
end

if (~exist('dataset_name', 'var'))  % Can be any of 'sift_1M',
                                    % 'gist_1M', 'sift_1B',
                                    % 'gist_80M', 'image_80M'
% NOTE: 'gist_80M' and 'image_80M' are not fully supported.
  fprintf('"dataset_name" does not exist as a variable, which dataset?.\n');
  return
end
if (~exist('model_type', 'var'))  % Can be any of 'itq', 'okmeans',
                                  % 'ckmeans', 'okmeans0', 'ckmeans0'
  fprintf('"model_type" does not exist as a variable, which model?.\n');
  return
end
if (~exist('nbits', 'var'))  % Number of bits -- should be a
                             % multiple of 8 for ckmeans
  fprintf('"nbits" does not exist as a variable, how many bits?.\n');
  return
end
if (~exist('training', 'var'))  % 0 or 1 -- whether to do trining or not
  fprintf('"training" does not exist as a variable, are we training?.\n');
  return
end
if (~exist('results', 'dir'))
  mkdir('results');
end

addpath utils;
addpath search;
addpath itq;

fprintf('----------------------------------------------------\n');
fprintf('dataset name: %s\n', dataset_name);
fprintf('model type: %s\n', model_type);
fprintf('number of bits: %d\n', nbits);
if (training)
  fprintf('training: yes\n')
else
  fprintf('training: no\n')
end  
fprintf('\n');

model_file = sprintf('results/%s_%s_%d', dataset_name, model_type, nbits);

if strcmp(dataset_name, 'sift_1M')
  datahome = INRIA_HOME;
  N = 10^6;
elseif strcmp(dataset_name, 'sift_1B')
  datahome = INRIA_HOME;
  nmillion = 1000;
  N = 10^6 * nmillion;
elseif strcmp(dataset_name, 'gist_1M')
  datahome = INRIA_HOME;
  N = 10^6;
elseif strcmp(dataset_name, 'gist_80M')
  datahome = TINY_HOME;
  N = 79*10^6;
elseif strcmp(dataset_name, 'image_80M')
  datahome = TINY_HOME;
  N = 79*10^6;
else
  fprintf('dataset not supported.\n');
  continue;
end

if (training) %% If the models should be trained.

if strcmp(dataset_name, 'sift_1M')
  Ntraining = 10^5;
  trdata = fvecs_read([datahome, '/ANN_SIFT1M/sift/sift_learn.fvecs']);
elseif strcmp(dataset_name, 'sift_1B')
  Ntraining = 10^6;
  trdata = b2fvecs_read([datahome, '/ANN_SIFT1B/bigann_learn.bvecs'], ...
                        [1 Ntraining]);
elseif strcmp(dataset_name, 'gist_1M')
  Ntraining = 5*10^5;
  trdata = fvecs_read([datahome, '/ANN_GIST1M/gist/gist_learn.fvecs']);
elseif strcmp(dataset_name, 'gist_80M')
  Ntraining = 10^6;
  trdata = single(read_tiny_binary_gist_core([datahome, ...
                    '/tinygist80million.bin'], uint64([1:Ntraining])));
elseif strcmp(dataset_name, 'image_80M')
  Ntraining = 10^6;
  trdata = single(read_tiny_binary_big_core([datahome, '/tiny_images.bin'], ...
                                            uint64([1:Ntraining])));
end

if (~exist('Ntraining'))
  Ntraining = size(trdata,2);
else
  assert(size(trdata,2) == Ntraining);
end

fprintf('trdata loaded, size(trdata) = (%d, %.1e).\n', ...
        size(trdata, 1), size(trdata, 2));

%% Train the quantization model on trdata

model = train_model(trdata, dataset_name, model_type, nbits);
save(model_file, 'model');

end

if (~training)  %% If a pre-trained model should be loaded for evaluation.

if (~exist([model_file, '.mat'], 'file'))
  fprintf('Model file %s does not exist.', model_file);
  return;
end

fprintf('loading model file (%s).\n', model_file);
load(model_file, 'model');

end

%% Quantize the base and query datasets by the quantizer (model).

t1 = 0;
cbase = zeros(ceil(nbits/8), N, 'uint8');
nbuffer = 10^6;
for i=1:floor(N/nbuffer)
  fprintf('%d/%d (%.2f)\r', i, floor(N/nbuffer), t1);
  range = [(i-1)*nbuffer+1 (i)*nbuffer];
  if strcmp(dataset_name, 'sift_1M')
    base = fvecs_read([datahome, '/ANN_SIFT1M/sift/sift_base.fvecs'], range); 
  elseif strcmp(dataset_name, 'sift_1B')
    base = b2fvecs_read([datahome, '/ANN_SIFT1B/bigann_base.bvecs'], range);
  elseif strcmp(dataset_name, 'gist_1M')
    base = fvecs_read([datahome, '/ANN_GIST1M/gist/gist_base.fvecs'], range); 
  end

  t0 = tic;
  if (strcmp(model.type, 'okmeans') || ...
          strcmp(model.type, 'itq'))
    cbase(:, (i-1)*nbuffer+1:(i)*nbuffer) = quantize_by_okmeans(base, model);
  elseif (strcmp(model.type, 'ckmeans'))
    cbase(:, (i-1)*nbuffer+1:(i)*nbuffer) = quantize_by_ckmeans(base, model);
  end
  t1 = toc(t0);
end

query = [];
if strcmp(dataset_name, 'sift_1M')
  query = fvecs_read([datahome, '/ANN_SIFT1M/sift/sift_query.fvecs']);
elseif strcmp(dataset_name, 'sift_1B')
  query = b2fvecs_read([datahome, '/ANN_SIFT1B/bigann_query.bvecs']);
elseif strcmp(dataset_name, 'gist_1M')
  query = fvecs_read([datahome, '/ANN_GIST1M/gist/gist_query.fvecs']);
end
if (isempty(query))
  queryR = [];
else
  if (strcmp(model.type, 'ckmeans'))
    [qbase, queryR] = quantize_by_ckmeans(query, model);
  elseif (strcmp(model.type, 'okmeans') || ...
          strcmp(model.type, 'itq'))
    [qbase, queryR] = quantize_by_okmeans(query, model);
  end
end

%% Load ground-truth labels.

max_n_queries = 10000;
nquery = min(max_n_queries, size(query, 2));
k = 10000;  % number of nearest neighbors to retrieve.
fprintf('nquery = %d, k = %d\n', nquery, k);

if strcmp(dataset_name, 'sift_1M')
  ids = ivecs_read ([datahome, '/ANN_SIFT1M/sift/sift_groundtruth.ivecs']);
elseif strcmp(dataset_name, 'sift_1B')
  ids = ivecs_read([datahome, '/ANN_SIFT1B/gnd/idx_', num2str(nmillion), ...
                    'M.ivecs']);
elseif strcmp(dataset_name, 'gist_1M')
  ids = ivecs_read ([datahome, '/ANN_GIST1M/gist/gist_groundtruth.ivecs']);
end
ids_gnd = ids(1, 1:nquery) + 1;

%% Perform evaluation by using different distance measures.

if (strcmp(model.type, 'okmeans') || ...
    strcmp(model.type, 'itq'))
  fprintf('Asymmetric Hamming distance:\n');
  ids_ah = asym_hamm_nns(cbase, queryR(:,1:nquery), model.d, k);
  recall_at_k_ah = test_compute_stats(ids_gnd, ids_ah, k);
  save(model_file, 'recall_at_k_ah', '-append');
  
  fprintf('Hamming distance:\n');
  ids_h = hamm_nns(cbase, qbase, k);
  recall_at_k_h = test_compute_stats(ids_gnd, ids_h, k);
  save(model_file, 'recall_at_k_h', '-append');
end

if (strcmp(model.type, 'ckmeans'))
  % There exists a more direct way to implement SQD by using a shared
  % lookup table accross all of the queries, but that should not be
  % that much different from creating a query-specific lookup table
  % for each one of the queries, when the query is represented by its
  % reconstruction using the ckmeans model.
  fprintf('Symmetric quantizer distance (SQD):\n');
  centers = double(cat(3, model.centers{:}));  % Assuming that all of the
                                               % centers have similar
                                               % dimensionality.
  queryR2 = double(reconstruct_by_ckmeans(qbase, model));
  [ids_sqd ~] = linscan_aqd_knn_mex(cbase, queryR2(:, 1:nquery), ...
                                    size(cbase, 2), model.nbits, k, centers);
  recall_at_k_sqd = test_compute_stats(ids_gnd, ids_sqd, k);
  save(model_file, 'recall_at_k_sqd', '-append');

  fprintf('Asymmetric quantizer distance (AQD):\n');
  centers = double(cat(3, model.centers{:}));  % Assuming that all of the
                                               % centers have similar
                                               % dimensionality.
  queryR = double(queryR);
  [ids_aqd ~] = linscan_aqd_knn_mex(cbase, queryR(:, 1:nquery), ...
                                    size(cbase, 2), model.nbits, k, centers);
  recall_at_k_aqd = test_compute_stats(ids_gnd, ids_aqd, k);
  save(model_file, 'recall_at_k_aqd', '-append');
end

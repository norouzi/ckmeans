training = 1;
model_types = {'itq', 'okmeans', 'ckmeans'}
dataset_name = 'sift_1M';
for nbits = [32 64 128]
  for i=1:numel(model_types)
    model_type = model_types{i};
    fprintf('RUN.m :\n');
    RUN;
  end
end

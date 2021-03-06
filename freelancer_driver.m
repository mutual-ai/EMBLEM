%{
Copyright [2014] [Do-kyum Kim, Matthew Der and Lawrence K. Saul]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

%}

%{
Desc
    This function loads the 'freelancer' dataset and train EMBLEM on the dataset.

Input
    split: the split to train EMBLEM. There are 12 splits in the 'freelancer' dataset.
    count_labeled: number of labeled examples. This specifies a split to load.
    interval: width of a range constraint on the target mean.
              We used 0.1 in our experiments.
    For description of the other arguments, please read emblem.m.

%}


function [] = freelancer_driver(split, count_labeled, assumption, lambda, c, use_pcg, use_fn_handle, pcg_tol, em_tol, print_status, interval, use_precond)

addpath('/home/dok027/liblinear/liblinear-1.93/matlab');

fprintf('=============================================================\n');
fprintf('split: %d\n', split);
fprintf('count_labeled: %d\n', count_labeled);
fprintf('assumption: %d\n', assumption);
fprintf('lambda: %f\n', lambda);
fprintf('c: %f\n', c);
fprintf('use_pcg: %d\n', use_pcg);
fprintf('use_fn_handle: %d\n', use_fn_handle);
fprintf('pcg_tol: %e\n', pcg_tol);
fprintf('em_tol: %e\n', em_tol);
fprintf('print_status: %d\n', print_status);
fprintf('interval: %e\n', interval);
fprintf('use_precond: %d\n', use_precond);
fprintf('=============================================================\n');

load('freelancer.mat', 'tfidf_matrix', 'y');
X = tfidf_matrix;
clear tfidf_matrix;

load(sprintf('freelancer_splits%d_labeled%d.mat', 12, count_labeled), 'idxLabs');

[d, num_total] = size(X);
idxUnls = setdiff(1:num_total, idxLabs(split, :));
Xl = X(:, idxLabs(split, :));
yl = y(idxLabs(split, :));
Xu = X(:, idxUnls);
yu = y(idxUnls);
count_unlabeled = size(Xu, 2);

sample_mean = 0.416;
sample_std = 0.9096;
sample_count = 2000;
mean_upper_bound = sample_mean + interval * sample_std / sqrt(sample_count);
mean_lower_bound = sample_mean - interval * sample_std / sqrt(sample_count);

tic;
[w, b] = liblinear_and_emblem(Xl, yl, Xu, assumption, lambda, c, use_pcg, use_fn_handle, pcg_tol, em_tol, print_status, mean_upper_bound, mean_lower_bound, use_precond);
em_time = toc;

idx_unused_labeled = find(yu~=0);
count_test = length(idx_unused_labeled);
x_test = Xu(:, idx_unused_labeled);
y_test = yu(idx_unused_labeled);

count_correct_labeled_by_semisupervised = sum(sign(Xl'*w+b) == yl);
count_correct_unlabeled_by_semisupervised = sum(sign(x_test'*w+b) == y_test);

error_labeled_by_semisupervised = (count_labeled - count_correct_labeled_by_semisupervised) / count_labeled;
error_unlabeled_by_semisupervised = (count_test - count_correct_unlabeled_by_semisupervised) / count_test;

fprintf('em time: %d\n', em_time);
fprintf('error (labeled): %.4f\n', error_labeled_by_semisupervised);
fprintf('error (unlabeled): %.4f\n', error_unlabeled_by_semisupervised);



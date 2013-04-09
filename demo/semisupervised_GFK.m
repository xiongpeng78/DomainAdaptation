function Ex_GFK()
addpath '../code/helper/'
addpath '../code/main_algorithm/GFK/'
addpath '../database/OC10/'
% This shows how to use GFK in a 1-nearest neighbor classifier.

% ref: Geodesic Flow Kernel for Unsupervised Domain Adaptation.  
% B. Gong, Y. Shi, F. Sha, and K. Grauman.  
% Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition (CVPR), Providence, RI, June 2012.

% Contact: Boqing Gong (boqinggo@usc.edu)


%-------------------------I. setup source/target domains----------------------
% Four domains: { Caltech10, amazon, webcam, dslr }
src = 'Caltech10';
tgt = 'webcam';

d = 20; % subspace dimension, the following dims are used in the paper:
% webcam-dslr: 10
% dslr-amazon: 20
% webcam-amazon: 10
% caltech-webcam: 20
% caltech-dslr: 10
% caltech-amazon: 20
% Note the dim from X to Y is the same as that from Y to X.

nPerClassInSource = 20; 
nPerClassInTarget = 3;
% 20 per class when Caltech/Amazon/Webcam is the source domain, and 
% 8 when DSLR is the source domain.

%--------------------II. prepare data--------------------------------------
load(['../dataset/OC10/', src, '_SURF_L10.mat']);     % source domain
fts = fts ./ repmat(sum(fts,2),1,size(fts,2)); 
Xs = zscore(fts,1);    clear fts
Ys = labels;           clear labels
Ps = princomp(Xs);  % source subspace

load(['../dataset/OC10/', tgt, '_SURF_L10.mat']);     % target domain
fts = fts ./ repmat(sum(fts,2),1,size(fts,2)); 
Xt = zscore(fts,1);     clear fts
Yt = labels;            clear labels
Pt = princomp(Xt);  % target subspace

fprintf('\nsource (%s) --> target (%s):\n', src, tgt);
fprintf('round     accuracy\n');
%--------------------III. run experiments----------------------------------
round = 20; % 20 random trials
tot = 0;
for iter = 1 : round 
    fprintf('%4d', iter);
    
    inds = split(Ys, nPerClassInSource);
    Xs_training = Xs(inds,:);
    Ys_training = Ys(inds); clear inds
    
    [training_inds testing_inds] = split(Yt, nPerClassInTarget);
    Xt_training = Xt(training_inds,:);
    Yt_training = Yt(training_inds);
    
    Xt_testing = Xt(testing_inds,:);
    Yt_testing = Yt(testing_inds);
    
    
    %---------------III.A. PLS --------------------------------------------
    % Ps = PLS(Xr, OneOfKEncoding(Yr), 3*d);   
    % PLS generally leads to better performance.
    % A nice implementation is publicaly available at http://www.utd.edu/~herve/
    
    G = GFK([Ps,null(Ps')], Pt(:,1:d));
    [junk, accy] = my_kernel_knn(G, Xs_training, Ys_training, Xt_training, Yt_training, Xt_testing, Yt_testing);   
    fprintf('\t\t%2.2f%%\n', accy*100);
    tot = tot + accy;
end
fprintf('mean accuracy: %2.2f%%\n\n', tot/round*100);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [prediction accuracy] = my_kernel_knn(M, Xs_training, Ys_training, Xt_training, Yt_training, Xt_testing, Yt_testing)
dist = [Xs_training*M*Xt_testing'; Xt_training*M*Xt_testing'] ;
[junk, maxIDX] = max(dist);

Y = [Ys_training; Yt_training];
prediction = Y(maxIDX);
accuracy = sum( prediction==Yt_testing ) / length(Yt_testing); 
end

function [idx1 idx2] = split(Y,nPerClass, ratio)
% [idx1 idx2] = split(X,Y,nPerClass)
idx1 = [];  idx2 = [];
for C = 1 : max(Y)
    idx = find(Y == C);
    rn = randperm(length(idx));
    if exist('ratio')
        nPerClass = floor(length(idx)*ratio);
    end
    idx1 = [idx1; idx( rn(1:min(nPerClass,length(idx))) ) ];
    idx2 = [idx2; idx( rn(min(nPerClass,length(idx))+1:end) ) ];
end
end
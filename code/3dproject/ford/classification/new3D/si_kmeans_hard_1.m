%imports
researchPath = '/mnt/neocortex/scratch/jumpbot/research/code/3dproject/';
addpath(genpath(strcat(researchPath,'/library/')));
addpath(genpath(strcat(pwd,'/new3D_spinImages/')));

%load parameters
parameters = loadParameters('./', '1_pyr3_hidden2048_ps16_gs2_imgW16_minN10_r2.txt');
load_fixed_new_3D();

%create your extractors
si = extractor_new3D(siPaths, parameters.radius, parameters.imgW, parameters.minN);

suffix = 'kmeans_hard_pyr3_h2048_imgW16_minN10_r2';
kmeans = KMeansHard(parameters.numHidden,false);
kmeans.savepath = sprintf('%s/%s/results/si/',pwd,suffix);
ensure(kmeans.savepath);
kmeans.savepath = strcat(kmeans.savepath, 'encoder.mat');

%stack them however you want to
stack1 = struct;
stack1.extractor = si;
stack1.encoder = kmeans;

%put the stacks together
stacks = stack1;

%create your svm
svm = SVM_car;
svm.resultsPath = sprintf('%s/%s/results/si/', pwd, suffix);
svm.savePath    = sprintf('%s/%s/svm/si/', pwd, suffix);
ensure(svm.savePath);
ensure(svm.resultsPath);

%run the pipeline
new3D_pipeline(stacks, svm, parameters, suffix);
%imports
researchPath = '/mnt/neocortex/scratch/jumpbot/research/code/3dproject/';
addpath(genpath(strcat(researchPath,'/library/')));

%some parameters
root = '/mnt/neocortex/scratch/jumpbot/data/3dproject/withlabels/';
trainRoot = strcat(root,'train/');
testRoot = strcat(root,'test/');

%load 2D things
encoder2D = load('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/hog_kmeans_tri_pyr3_h2048_imgW16_minN10_r2/results/hog/encoder.mat');
model2D = load('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/hog_kmeans_tri_pyr3_h2048_imgW16_minN10_r2/svm/hog/model.mat');
hogparam = loadParameters('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/', '1_pyr3_hidden2048_ps16_gs2_imgW16_minN10_r2.txt');
encoder2D = encoder2D.encoder;
model2D = model2D.model;

%load 3D things
model3D = load('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/si_kmeans_tri_pyr3_h2048_imgW16_minN10_r2_imgperclass80_plus/svm/si/model.mat');
encoder3D = load('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/si_kmeans_tri_pyr3_h2048_imgW16_minN10_r2_imgperclass80_plus/results/si/encoder.mat');
siparam = loadParameters('/mnt/neocortex/scratch/jumpbot/research/code/3dproject/ford/classification/new3D/', '1_pyr3_hidden2048_ps16_gs2_imgW16_minN10_r2.txt');
encoder3D = encoder3D.encoder;
model3D = model3D.model;
three_dir = 'with_nms';
target_dir = sprintf('%s/%s',pwd,three_dir);
ensure(target_dir);

%read up the positive examples
positives = '/mnt/neocortex/scratch/norrathe/data/car_patches/random_sample/pos_batch/data_batch_1_res.txt';
[description, score_cnn] = textread(positives,'%s %f');

%parse and do nms
all_pos = [];
for i = 1:length(description)
    str = cell2mat(description(i));
    x = strsplit(str,'_');
    scene = cell2mat(x(1)); 
    cam = cell2mat(x(2));
    q = strsplit(cam,'cam'); camnum = str2num(cell2mat(q(2)));
    q = strsplit(scene,'obj'); scenenum = str2num(cell2mat(q(2)));
    q = strsplit(cell2mat(x(6)),'.'); fourth = str2num(cell2mat(q(1)));
    third = str2num(cell2mat(x(5)));
    second = str2num(cell2mat(x(4)));
    first = str2num(cell2mat(x(3)));
    bndbox = [first,second,third,fourth];
    info = [scenenum,camnum,bndbox];
    all_pos = [all_pos;info];
end
all_scenes = unique(all_pos(:,1));
for i = 1:size(all_scenes,2)
    scene = all_scenes(i);
    all_pos_i = find(all_pos==scene);
    all_scene_pos = all_pos(all_pos_i,:);
    
end

%read up the negative examples
negatives = '/mnt/neocortex/scratch/norrathe/data/car_patches/random_sample/neg_batch/data_batch_1_res.txt';
[description, score_cnn] = textread(negatives,'%s %f');
all_neg = [];
for i = 1:length(description)
    str = cell2mat(description(i));
    x = strsplit(desc,'_');
    scene = cell2mat(x(1)); 
    cam = cell2mat(x(2));
end


%read up the positive examples
positives = '/mnt/neocortex/scratch/norrathe/data/car_patches/random_sample/pos_batch/data_batch_1_res.txt';
[description, score_cnn] = textread(positives,'%s %f');
pos_scores_cnn = [];
pos_scores_3D = [];
pos_scores_2D = [];
numSamples = 200;
selection = randsample(length(description),numSamples);
pos_count = 0;
for i = 1:length(selection)
    desc = cell2mat(description(selection(i)));
    %parse out the scene, cam
    x = strsplit(desc,'_');
    scene = cell2mat(x(1));
    cam = cell2mat(x(2));
    three_cam = sprintf('three_%s',cam);
    sceneFolder = fullfile(trainRoot,scene);
    matLocation = fullfile(sceneFolder,sprintf('%s.mat',cam));
    three_matLocation = fullfile(sceneFolder,sprintf('%s.mat',three_cam));
    load(matLocation);
    load(three_matLocation);
    
    %get the 2D score
    minX = str2num(cell2mat(x(3)));
    minY = str2num(cell2mat(x(4)));
    maxX = str2num(cell2mat(x(5)));
    maxY = cell2mat(x(6));
    maxY = strsplit(maxY,'.');
    maxY = str2num(cell2mat(maxY(1)));
    bndbox = [minX, minY, maxX, maxY];
    patch = imcrop(img,[bndbox(1),bndbox(2),abs(bndbox(1)-bndbox(3)),abs(bndbox(2)-bndbox(4))]);
    [label2D,score2D] = get2Dscore(patch,model2D,encoder2D,hogparam);
    
    %get the 3D score
    inside = findPointsIn(bndbox,data(:,1:2));
    inside = data(inside,:);
    pc = inside(:,6:8);
    if isempty(pc)
        continue;
    end
    [label3D, score3D] = get3Dscore(pc,inside,model3D,encoder3D,siparam);
    
    pos_scores_cnn = [pos_scores_cnn,score_cnn(i)];     %update cnn scores
    pos_scores_2D = [pos_scores_2D,score2D];            %update 2D score
    pos_scores_3D = [pos_scores_3D,score3D];            %update 3D score
    pos_count = pos_count + 1;
end

%read up the negative examples
negatives = '/mnt/neocortex/scratch/norrathe/data/car_patches/random_sample/neg_batch/data_batch_1_res.txt';
[description, score_cnn] = textread(negatives,'%s %f');
neg_scores_cnn = [];
neg_scores_3D = [];
neg_scores_2D = [];
numSamples = 2*numSamples;
selection = randsample(length(description),numSamples);
neg_count = 0;
for i = 1:length(selection)
    desc = cell2mat(description(selection(i)));
    %parse out the scene, cam
    x = strsplit(desc,'_');
    scene = cell2mat(x(1));
    cam = cell2mat(x(2));
    three_cam = sprintf('three_%s',cam);
    sceneFolder = fullfile(trainRoot,scene);
    matLocation = fullfile(sceneFolder,sprintf('%s.mat',cam));
    three_matLocation = fullfile(sceneFolder,sprintf('%s.mat',three_cam));
    load(matLocation);
    load(three_matLocation);
    
    %get the 2D score
    minX = str2num(cell2mat(x(3)));
    minY = str2num(cell2mat(x(4)));
    maxX = str2num(cell2mat(x(5)));
    maxY = cell2mat(x(6));
    maxY = strsplit(maxY,'.');
    maxY = str2num(cell2mat(maxY(1)));
    bndbox = [minX, minY, maxX, maxY];
    patch = imcrop(img,[bndbox(1),bndbox(2),abs(bndbox(1)-bndbox(3)),abs(bndbox(2)-bndbox(4))]);
    [label2D,score2D] = get2Dscore(patch,model2D,encoder2D,hogparam);
    
    %get the 3D score
    inside = findPointsIn(bndbox,data(:,1:2));
    inside = data(inside,:);
    pc = inside(:,6:8);
    if isempty(pc)
        continue;
    end
    [label3D, score3D] = get3Dscore_plus(pc,inside,model3D,encoder3D,siparam);
    
    neg_scores_cnn = [neg_scores_cnn,score_cnn(i)];     %update cnn scores
    neg_scores_2D = [neg_scores_2D,score2D];            %update 2D score
    neg_scores_3D = [neg_scores_3D,score3D];            %update 3D score
    neg_count = neg_count + 1;
end

fprintf('%d positives\n',pos_count);
fprintf('%d negatives\n',neg_count);

%save things
neg_scores = struct();
neg_scores.cnn = neg_scores_cnn;
neg_scores.two = neg_scores_2D;
neg_scores.three = neg_scores_3D;
neg_matrix = [neg_scores_cnn;neg_scores_2D;neg_scores_3D];
neg_scores.matrix = neg_matrix;

pos_scores = struct();
pos_scores.cnn = pos_scores_cnn;
pos_scores.two = pos_scores_2D;
pos_scores.three = pos_scores_3D;
pos_matrix = [pos_scores_cnn;pos_scores_2D;pos_scores_3D];
pos_scores.matrix = pos_matrix;

neg_target = sprintf('%s/neg_scores_%d.mat',target_dir, numSamples);
pos_target = sprintf('%s/pos_scores_%d.mat',target_dir, numSamples);
save(neg_target,'neg_scores');
save(pos_target,'pos_scores');


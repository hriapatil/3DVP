function exemplar_test_joint(cls, name, is_train, is_continue, is_pascal)

% load model
model_name = sprintf('data/%s_%s_final.mat', cls, name);
object = load(model_name);
model = object.model;
model.thresh = min(-1, model.thresh);

% KITTI path
globals;

if is_pascal
    pascal_init;
    if is_train
        ids = textread(sprintf(VOCopts.imgsetpath, 'val'), '%s');
    else
        ids = textread(sprintf(VOCopts.imgsetpath, 'test'), '%s');
    end
    opt.VOCopts = VOCopts;
    image_dir = [];
else
    root_dir = KITTIroot;

    if is_train == 1
        data_set = 'training';
    else
        data_set = 'testing';
    end

    % get sub-directories
    cam = 2; % 2 = left color camera
    image_dir = fullfile(root_dir, [data_set '/image_' num2str(cam)]); 

    % get test image ids
    object = load('kitti_ids_new.mat');
    if is_train == 1
        ids = object.ids_val;
    else
        ids = object.ids_test;
    end
    opt = [];
end

filename = sprintf('data/%s_%s_test.mat', cls, name);

% run detector in each image
if is_continue && exist(filename, 'file')
    load(filename);
else
    N = numel(ids);
    parfor i = 1:N
        fprintf('%s %s: %d/%d\n', cls, name, i, N);
        
        if is_pascal
            file_img = sprintf(opt.VOCopts.imgpath, ids{i});
        else
            file_img = sprintf('%s/%06d.png', image_dir, ids(i));
        end        
        
        im = imread(file_img);
        [dets, boxes] = imgdetect(im, model, model.thresh);
    
        if ~isempty(boxes)
            boxes = reduceboxes(model, boxes);
            [dets, boxes] = clipboxes(im, dets, boxes);
            num = size(dets, 1);
            for j = 1:num
                dets(j,5) = model.centers(dets(j,5));
            end            
            % without non-maximum suppression
            boxes1{i} = dets;
            parts1{i} = boxes;
        else
            boxes1{i} = [];
            parts1{i} = [];
        end
    end  
    save(filename, 'boxes1', 'parts1', '-v7.3');
end
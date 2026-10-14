%% segment and masked data
seg_len = 60;% number of movements per segments, 60 is about 1 min
min_masked_perc = 0.2;% minium masked percentage of seg_len
max_masked_perc = 0.5;% maxium masked percentage of seg_len
all_data_num = 100000;% number of all data sequences for train, valid and test
train_perc = 0.7;% train data percentage
valid_perc = 0.2;% valid data percentage
test_perc = 0.1;% test data percentage
token_list = [char(65:90),char(97:122),char(48:57)];% transform behavior class index to token
mask_token = '-';

trial_num = length(unique_name);

all_data_cell = cell(all_data_num,2);

unique_class = unique(cell2mat(class_cell));

min_num = round(seg_len*min_masked_perc);
max_num = round(seg_len*max_masked_perc);
train_num = round(all_data_num*train_perc);
valid_num = round(all_data_num*valid_perc);
test_num = round(all_data_num*test_perc);

rng('default');
tic
for k = 1:size(all_data_cell,1)
    %% random select trials
    randl = randperm(trial_num);
    rand_1 = randl(1);
    sel_trial = class_cell{rand_1,1};
    %% random select seg_len
    sel_len = size(sel_trial,1);
    rand_start = randperm(sel_len-seg_len);
    sel_seg = sel_trial(rand_start(1):(rand_start(1)+60-1),1);
    temptk = token_list(sel_seg);
    all_data_cell{k,2} = temptk;
    %% random mask
    temprandm = randperm(max_num-min_num);
    randm = temprandm(1)+min_num;
    temprandtm = randperm(seg_len);
    randtm = temprandtm(1:randm);
    temptk(randtm) = mask_token;
    all_data_cell{k,1} = temptk;
    %% count
    if rem(k,10000) == 0
        disp(k)
        toc
    end
end
toc

all_rand = randperm(all_data_num);
train_rand = all_rand(1:train_num);
valid_rand = all_rand((train_num+1):(train_num+valid_num));
test_rand = all_rand((train_num+valid_num+1): ...
    (train_num+valid_num+test_num));

train_data = all_data_cell(train_rand,:);
valid_data = all_data_cell(valid_rand,:);
test_data = all_data_cell(test_rand,:);
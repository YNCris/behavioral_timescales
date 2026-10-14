# -*- coding: utf-8 -*-
"""
Created on Tue Sep 17 11:26:44 2024

@author: yhan
"""

import brainpy as bp
import brainpy.math as bm
import brainpy_datasets as bd
import matplotlib.pyplot as plt
import scipy.io as scio
import os
from tqdm import tqdm
import numpy as np
import random
import copy
from sklearn.decomposition import PCA
from scipy.ndimage import median_filter

bm.set_environment(x64=True, mode=bm.batching_mode)
bm.set_platform('cpu')

bp.__version__

def idx2savelist(tempdist):
    """
    Transfer clustering idx to segmentation positions.
    """
    # Add head index
    addheadidx = np.vstack([tempdist[0]-1, tempdist])
    diffidx = np.diff(addheadidx,axis=0)
    bwidx = diffidx != 0
    startlist = np.where(bwidx == 1)[0].reshape(-1,1)

    # Add tail index
    addtailidx = np.vstack([tempdist, tempdist[-1]-1])
    diffidx = np.flipud(np.diff(np.flipud(addtailidx),axis=0))
    bwidx = diffidx != 0
    endlist = np.where(bwidx == 1)[0].reshape(-1,1)

    # Combine startlist, endlist, and idx(startlist) into seglist
    seglist = np.hstack([
        startlist, 
        endlist, 
        tempdist[startlist].reshape(-1,1)])
    
    return seglist

def moving_average(data, window_size):
    return np.convolve(data, \
                       np.ones(window_size)/window_size, mode='same')
        
def pc_norm_01(selpc):
    min_selpc = np.matmul(\
                          np.ones([np.size(selpc,0),1]),\
                              np.min(selpc,0).reshape(1,-1))
    max_selpc = np.matmul(\
                          np.ones([np.size(selpc,0),1]),\
                              np.max(selpc,0).reshape(1,-1))
        
    mean_selpc = np.matmul(\
                          np.ones([np.size(selpc,0),1]),\
                              np.mean(selpc,0).reshape(1,-1))
        
    std_selpc = np.matmul(\
                          np.ones([np.size(selpc,0),1]),\
                              np.std(selpc,0).reshape(1,-1))
    
    norm_selpc = (selpc-mean_selpc)/(max_selpc-min_selpc)
    
    return norm_selpc
    

#%% set path
rootpath = r'E:\MTPM_body_language'
beh_neu_path = rootpath + r'\beh_neu_20240412'
#%% load data
files = os.listdir(beh_neu_path)

rootnames = []
for file in files:
    #%
    splname = file.split('-')
    if splname[0] == 'free':
        if splname[-1] == 'neu.mat':
            rootnames.append(file)
            
            
all_data_cell = []
for rootname in tqdm(rootnames):
    #%
    temprootname = rootname[0:-8]
    
    tempneu = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-neu.mat')
        
    ttneu = tempneu['dff_smo_Fc'].transpose()
    
    tempposeself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-pose-tpm.mat')
        
    ttposeself = tempposeself['coords3d']
    
    tempposepartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-pose-free.mat')
        
    ttposepartner = tempposepartner['coords3d']
    
    tempmovself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-beh_mod-tpm.mat')

    ttmovself = np.vstack(tempmovself['beh_mod_list'][:,1])
    
    tempmovpartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-beh_mod-free.mat')

    ttmovpartner = np.vstack(tempmovpartner['beh_mod_list'][:,1])
    
    tempdist = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-distance-free.mat')
        
    ttdist = np.vstack(tempdist['dist_data'][:,1])

    all_data_cell.append([
        ttneu,
        ttposeself,
        ttposepartner,
        ttmovself,
        ttmovpartner,
        ttdist,
        temprootname])
    
#%% split far-close-far trial
fs = 30;
baseline_far_time = 15##s
cut_all_time = 10*60##s

baseline_far_frame = baseline_far_time*fs
cut_all_frame = cut_all_time*fs;

raw_trial_cell = []
trial_length = []

for k in tqdm(range(0,len(all_data_cell))):
    #% load data
    tempdist = all_data_cell[k][5]
    
    #% select trials
    distsavelist = idx2savelist(tempdist)

    diff_len = distsavelist[:,1]-distsavelist[:,0]+1
    
    far_idx = distsavelist[:,2]==0
    
    diff_len_idx = diff_len>=baseline_far_frame
    
    selidx = far_idx&diff_len_idx
    
    find_save_list = np.where(selidx)[0][0]
    
    sel_save_list = distsavelist[find_save_list::,:]
    
    # modify to the same lengh of baseline
    
    sel_save_list[0,0] = sel_save_list[0,1]-baseline_far_frame
    
    # 选择最终的 close 列表
    tempstart = sel_save_list[0, 0]
    tempend = sel_save_list[0, 0] + cut_all_frame

    newname = all_data_cell[k][6] + '-cut'
    
    
    all_data_1 = all_data_cell[k][0][tempstart:tempend, :]
    all_data_2 = all_data_cell[k][1][tempstart:tempend, :]
    all_data_3 = all_data_cell[k][2][tempstart:tempend, :]
    all_data_4 = all_data_cell[k][3][tempstart:tempend, :]
    all_data_5 = all_data_cell[k][4][tempstart:tempend, :]
    all_data_6 = all_data_cell[k][5][tempstart:tempend, :]

    raw_trial_cell.append([\
       newname, all_data_1, all_data_2, all_data_3, all_data_4, 
       all_data_5, all_data_6, all_data_cell[k][0]])
        
    trial_length.append(np.size(all_data_1,0))

#%% sort trial by brain areas
sort_brain_name_list = [
    '1tpmss',
    '2tpmss',
    '3tpmss',
    '4tpmss',
    '5tpmss',
    '1tpmpfc',
    '2tpmpfc',
    '3tpmpfc',
    '4tpmpfc',
    '5tpmpfc',
    '1tpmm',
    '2tpmm',
    '3tpmm',
    '4tpmm',
    '5tpmm',
    ]

sort_trial_cell = []

for k in range(len(sort_brain_name_list)):
    for m in range(len(raw_trial_cell)):
        tempname = raw_trial_cell[m][0]
        splname1 = tempname.split('-')
        
        if splname1[2] == sort_brain_name_list[k]:
            sort_trial_cell.append(raw_trial_cell[m])
            break
    
#%% pca
pca_cell = []

for k in tqdm(range(len(sort_trial_cell))):
    tempdata = sort_trial_cell[k]
    tempneu = tempdata[1]
    
    pca = PCA()
    
    X_pca = pca.fit_transform(tempneu)
    
    pca_cell.append(X_pca)
    
#%% prepare pca dataset
sel_pc_num = 150

pca_train = []

for temppc in pca_cell:
    selpc = temppc[:,0:sel_pc_num]
    
    norm_selpc = pc_norm_01(selpc)
    
    pca_train.append(norm_selpc)
    
#% split dataset, 按照每一只老鼠做数据集，每一只老鼠训练一个网络
'''
过去的自身和同伴行为预测未来的自身行为

输入：社交前的状态，自身同伴行为

pca价值对齐

输出：社交后的状态
'''

frame_delay = 0 #450 frames for far baseline

cut_len = cut_all_frame

XTrain = []
YTrain = []

XTrain_rand = []

    
for k in range(0,len(sort_trial_cell)):
    selfpose = sort_trial_cell[k][2]
    partnerpose = sort_trial_cell[k][3]
    
    before_selfpose = selfpose[0:cut_len-frame_delay,:].copy()
    before_partnerpose = partnerpose[0:cut_len-frame_delay,:].copy()
    
    after_selfpose = selfpose[frame_delay::,:].copy()
    
    before_pose = np.hstack([before_selfpose,before_partnerpose])
    
    # norm pose
    # cent_before_partnerpose = before_partnerpose[:,36:39]
    # cent_after_selfpose = after_selfpose[:,36:39]
    
    # for m in range(0,16):
    #     before_partnerpose[:,3*m:(3*m+3)] = \
    #         before_partnerpose[:,3*m:(3*m+3)]-\
    #         cent_before_partnerpose
    #     after_selfpose[:,3*m:(3*m+3)] = \
    #         after_selfpose[:,3*m:(3*m+3)]-\
    #         cent_after_selfpose
    
    # filt pose
    
    for m in range(np.size(before_partnerpose,1)):
        before_partnerpose[:,m] = median_filter(\
            before_partnerpose[:,m],15)
            
    for m in range(np.size(after_selfpose,1)):
        after_selfpose[:,m] = median_filter(\
            after_selfpose[:,m],15)
    
    
    XTrain.append(before_partnerpose)
    YTrain.append(after_selfpose)
    XTrain_rand.append(np.apply_along_axis(\
                       np.random.permutation, axis=0, \
                       arr=before_partnerpose))

# merge to tensor and add batch size = 1
XTrain = np.stack(XTrain,axis=0)
YTrain = np.stack(YTrain,axis=0)
XTrain_rand = np.stack(XTrain_rand,axis=0)

Train_pca = np.zeros([np.size(XTrain,0),\
                     np.size(XTrain,1),\
                         sel_pc_num])
    
for k in range(len(pca_train)):
    Train_pca[k,:,:] = pca_train[k]
    
    
#%% define reservior computing network
#%
class RCN(bp.DynamicalSystem):
  def __init__(self, 
               num_in, 
               leaky_rate, 
               in_connectivity, 
               num_hidden, 
               rec_connectivity, 
               num_out,
               spectral_radius):
    super(RCN, self).__init__()
    self.r = bp.dyn.Reservoir(
        num_in,
        num_hidden,
        leaky_rate = leaky_rate,
        in_connectivity = in_connectivity,
        rec_connectivity = rec_connectivity,
        spectral_radius = spectral_radius,
        comp_type='dense')
    self.o = bp.dnn.Dense(num_hidden, num_out, mode=bm.training_mode)

  def update(self, x):
    # print(f"Input shape: {x.shape}")
    # r_output = self.r(x)
    # print(f"Reservoir output shape: {r_output.shape}")
    # o_output = self.o(r_output)
    # print(f"Dense layer output shape: {o_output.shape}")
    # print(x.shape)
    r_output = self.r(x)
    o_output = self.o(r_output)
    # print(o_output.shape)
    return o_output

class resRCN(bp.DynamicalSystem):
  def __init__(self, 
               num_in, 
               leaky_rate, 
               in_connectivity, 
               num_hidden, 
               rec_connectivity, 
               num_out,
               spectral_radius):
    super(resRCN, self).__init__()
    self.r1 = bp.dyn.Reservoir(
        num_in,
        num_hidden,
        leaky_rate = leaky_rate,
        in_connectivity = in_connectivity,
        rec_connectivity = rec_connectivity,
        spectral_radius = spectral_radius,
        comp_type='dense')
    self.r2 = bp.dyn.Reservoir(
        num_hidden,
        num_hidden,
        leaky_rate = leaky_rate,
        in_connectivity = in_connectivity,
        rec_connectivity = rec_connectivity,
        spectral_radius = spectral_radius,
        comp_type='dense')
    # self.r3 = bp.dyn.Reservoir(
    #     num_hidden,
    #     num_hidden,
    #     leaky_rate = leaky_rate,
    #     in_connectivity = in_connectivity,
    #     rec_connectivity = rec_connectivity,
    #     spectral_radius = spectral_radius,
    #     comp_type='dense')
    # self.r4 = bp.dyn.Reservoir(
    #     num_hidden,
    #     num_hidden,
    #     leaky_rate = leaky_rate,
    #     in_connectivity = in_connectivity,
    #     rec_connectivity = rec_connectivity,
    #     spectral_radius = spectral_radius,
    #     comp_type='dense')
    # self.r5 = bp.dyn.Reservoir(
    #     num_hidden,
    #     num_hidden,
    #     leaky_rate = leaky_rate,
    #     in_connectivity = in_connectivity,
    #     rec_connectivity = rec_connectivity,
    #     spectral_radius = spectral_radius,
    #     comp_type='dense')
    # self.r6 = bp.dyn.Reservoir(
    #     num_hidden,
    #     num_hidden,
    #     leaky_rate = leaky_rate,
    #     in_connectivity = in_connectivity,
    #     rec_connectivity = rec_connectivity,
    #     spectral_radius = spectral_radius,
    #     comp_type='dense')
    self.o = bp.dnn.Dense(num_hidden, num_out, mode=bm.training_mode)

  def update(self, x):
    # print(f"Input shape: {x.shape}")
    # r_output = self.r(x)
    # print(f"Reservoir output shape: {r_output.shape}")
    # o_output = self.o(r_output)
    # print(f"Dense layer output shape: {o_output.shape}")
    # print(x.shape)
    # r1_output = self.r1(x)
    # r2_output = 0.5*self.r2(r1_output)+0.5*r1_output
    # r3_output = 0.5*self.r3(r2_output)+0.5*(r1_output+r2_output)/2
    # r4_output = 0.5*self.r4(r3_output)+\
    #     0.5*(r1_output+r2_output+r3_output)/3
    # r5_output = 0.5*self.r5(r4_output)+\
    #     0.5*(r1_output+r2_output+r3_output+r4_output)/4
    # r6_output = 0.5*self.r6(r5_output)+\
    #     0.5*(r1_output+r2_output+r3_output+r4_output+r5_output)/5
    # o_output = self.o(r6_output)
    
    r1_output = self.r1(x)
    r2_output = (self.r2(r1_output)+r1_output)/2
    # r3_output = (self.r3(r2_output)+r1_output+r2_output)/3
    # r4_output = (self.r4(r3_output)+r1_output+r2_output+r3_output)/4
    # r5_output = (self.r5(r4_output)+r1_output+r2_output+r3_output+r4_output)/5
    # r6_output = (self.r6(r5_output)+r1_output+r2_output+r3_output+r4_output+r5_output)/6
    o_output = self.o(r2_output)
    # print(o_output.shape)
    return o_output

class RCN_01(bp.DynamicalSystem):
  def __init__(self, 
               num_in, 
               leaky_rate, 
               in_connectivity, 
               num_hidden, 
               rec_connectivity, 
               num_out,
               spectral_radius):
    super(RCN_01, self).__init__()
    self.r = bp.dyn.Reservoir(
        num_in,
        num_hidden,
        leaky_rate = leaky_rate,
        in_connectivity = in_connectivity,
        rec_connectivity = rec_connectivity,
        spectral_radius = spectral_radius,
        comp_type='dense')
    self.o = bp.dnn.Dense(num_hidden, num_out, mode=bm.training_mode)

  def update(self, x):
    # print(f"Input shape: {x.shape}")
    # r_output = self.r(x)
    # print(f"Reservoir output shape: {r_output.shape}")
    # o_output = self.o(r_output)
    # print(f"Dense layer output shape: {o_output.shape}")
    # print(x.shape)
    r_output = self.r(x)
    o_output = bp.math.sigmoid(self.o(r_output))
    # print(o_output.shape)
    return o_output
#% set network parameters
# leaky_rate_list = [0.1,0.3,0.5,0.7,0.9]
# in_connectivity_list = [0.1,0.3,0.5,0.7,0.9]
# num_hidden_list = [10,200,800,3000]
# rec_connectivity_list = [0.1,0.3,0.5,0.7,0.9]
# spectral_radius_list = [0.01,0.1,1,10,100,1000]

# leaky_rate_list = [0.01]#调小精度高
# in_connectivity_list = [0.1]
# num_hidden_list = [1000]#调大精度高
# rec_connectivity_list = [0.1]
# spectral_radius_list = [None]

# param_list = []
# for temp_leaky_rate in leaky_rate_list:
#     for temp_in_connectivity in in_connectivity_list:
#         for temp_num_hidden in num_hidden_list:
#             for temp_rec_connectivity in rec_connectivity_list:
#                 for temp_spectral_radius in spectral_radius_list:
#                     param_list.append(np.hstack([
#                         temp_leaky_rate,
#                         temp_in_connectivity,
#                         temp_num_hidden,
#                         temp_rec_connectivity,
#                         temp_spectral_radius,
#                         ]))
#%% train step
# model_list = []
# rmse_list = []

# fig = plt.figure(figsize=(15, 12))

for k in tqdm(range(0,np.size(XTrain,0))):
# for k in [0]:
    #% create save folder
    tempname = sort_trial_cell[k][0]
    
    print(tempname)
    
    #% create model
    rcn_encoder = resRCN(
        num_in=48,
        leaky_rate=0.1,#memory length, 0.001 worse, 0.05 best
        in_connectivity=0.1,
        num_hidden=1000, 
        rec_connectivity=0.1,
        spectral_radius=None,
        num_out=sel_pc_num)
    
    rcn_decoder = resRCN(
        num_in=sel_pc_num,
        leaky_rate=0.1,#memory length, 0.1 best
        in_connectivity=0.1,
        num_hidden=1000, 
        rec_connectivity=0.1,
        spectral_radius=None,
        num_out=48)
    
    #% train
    # encoder
    reg_alpha = 1e-7#0.0001# 1 best balance
    
    trainer_encoder = bp.RidgeTrainer(rcn_encoder, alpha=reg_alpha)
    _ = trainer_encoder.predict(XTrain[k:(k+1),:,:])
    
    _ = trainer_encoder.fit([bm.asarray(XTrain[k:(k+1),:,:]),
                      bm.asarray(Train_pca[k:(k+1),:,:])])
    
    # model_list.append(model)
    
    pca_predict = bm.as_numpy(trainer_encoder.predict(\
          bm.asarray(XTrain[k:(k+1),:,:]), reset_state=True))
        
    selpc = pca_predict.reshape(np.size(pca_predict,1),-1)
    
    # norm_selpc = pc_norm_01(selpc)
    
    # norm_pca_predict = norm_selpc.reshape(1,\
    #                     np.size(norm_selpc,0),\
    #                         np.size(norm_selpc,1))
        
    pca_raw = bm.as_numpy(bm.asarray(Train_pca[k:(k+1),:,:]))
    
    pca_rmse = np.mean(np.sqrt((pca_predict-pca_raw)*\
                           (pca_predict-pca_raw)))
        
    # norm_pca_rmse = np.mean(np.sqrt((norm_pca_predict-pca_raw)*\
    #                        (norm_pca_predict-pca_raw)))
    
    print('pca_rmse')
    print(pca_rmse)
    # print('norm_pca_rmse')
    # print(norm_pca_rmse)
    
    # decoder
    trainer_decoder = bp.RidgeTrainer(rcn_decoder, alpha=reg_alpha)
    _ = trainer_decoder.predict(Train_pca[k:(k+1),:,:])
    
    _ = trainer_decoder.fit([bm.asarray(Train_pca[k:(k+1),:,:]),
                      bm.asarray(YTrain[k:(k+1),:,:])])
    
    # model_list.append(model)
    
    ys_predict = bm.as_numpy(trainer_decoder.predict(\
          bm.asarray(Train_pca[k:(k+1),:,:]), reset_state=True))
        
    ys_raw = bm.as_numpy(bm.asarray(YTrain[k:(k+1),:,:]))
    
    ys_rmse = np.mean(np.sqrt((ys_predict-ys_raw)*\
                           (ys_predict-ys_raw)))
        
        
    ys_pca_predict = bm.as_numpy(trainer_decoder.predict(\
          bm.asarray(pca_predict), reset_state=True))
    
    ys_pca_rmse = np.mean(np.sqrt((ys_pca_predict-ys_raw)*\
                           (ys_pca_predict-ys_raw)))
          
    
    print('ys_rmse')
    print(ys_rmse)
    print('ys_pca_rmse')
    print(ys_pca_rmse)
    
    #% show
    pca_int = 1
    
    show_pc_num = 10
    
    # plt.subplot(611)
    # for m in range(48):
    #     plt.plot(bm.arange(18000).to_numpy(),
    #               bm.as_numpy(XTrain)[k, :, m]+30*m,
    #               '-b',lw=0.25)
    # plt.axis([0,18000,-300,1900])
    # plt.title(tempname)
    
    # plt.subplot(612)
    # for m in range(show_pc_num):
    #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #               Train_pca[k, :, m]+pca_int*m,
    #               "-g",
    #               lw=0.25)
    # plt.axis([0,18000,0,show_pc_num])
    # plt.title('raw pca')
    
    # plt.subplot(613)
    # for m in range(show_pc_num):
    #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #               norm_pca_predict[0, :, m]+pca_int*m,
    #               "-r",
    #               lw=0.25)
    # plt.axis([0,18000,0,show_pc_num])
    # plt.title('predict pca')
    
    # plt.subplot(614)
    # for m in range(48):
    #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #               YTrain[k, :, m]+30*m,
    #               "-r",
    #               lw=0.25)
    # plt.axis([0,18000,-300,1900])
    # plt.title('Subject pose')
    
    # plt.subplot(615)
    # for m in range(48):
    #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #               ys_predict[0, :, m]+30*m,
    #               "-r",
    #               lw=0.25)
    # plt.axis([0,18000,-300,1900])
    # plt.title('predict pose')
    
    
    # plt.subplot(616)
    # for m in range(48):
    #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #               ys_pca_predict[0, :, m]+30*m,
    #               "-r",
    #               lw=0.25)
    # plt.axis([0,18000,-300,1900])
    # plt.title('state pca predict pose')

        
    # plt.show()
    
    # save
    
    save_XTrain = bm.as_numpy(XTrain)[k, :, :].reshape(\
                   np.size(XTrain,1),np.size(XTrain,2))
    save_Train_pca = Train_pca[k, :, :].reshape(\
                   np.size(Train_pca,1),np.size(Train_pca,2))
    save_pca_predict = pca_predict[0, :, :].reshape(\
                       np.size(pca_predict,1),np.size(pca_predict,2))
    save_YTrain = bm.as_numpy(YTrain)[k, :, :].reshape(\
                   np.size(YTrain,1),np.size(YTrain,2))
    save_ys_predict = ys_predict[0, :, :].reshape(\
                   np.size(ys_predict,1),np.size(ys_predict,2))
    save_ys_pca_predict = ys_pca_predict[0, :, :].reshape(\
                   np.size(ys_pca_predict,1),np.size(ys_pca_predict,2))
    
    save_train_name = tempname + '-rnn_ed_train_2layers.mat'
    scio.savemat(beh_neu_path + r'/' + save_train_name,\
                  {'XTrain':save_XTrain,\
                   'Train_pca':save_Train_pca,\
                   'pca_predict':save_pca_predict,\
                   'YTrain':save_YTrain,\
                   'ys_predict':save_ys_predict,\
                   'ys_pca_predict':save_ys_pca_predict,\
                   })
        
    print('save')
    print(save_train_name)
    
    
    #%
    
    
    #% other data cross validation
    # sel_other_idx = np.ones([np.size(XTrain,0),1])
    # sel_other_idx[k] = 0
    # sel_other_idx = sel_other_idx.flatten()
    
    # valid_XTrain = XTrain[sel_other_idx==1,:,:]
    # valid_Train_pca = Train_pca[sel_other_idx==1,:,:]
    # valid_YTrain = YTrain[sel_other_idx==1,:,:]
    
    # sel_other_num = np.where(sel_other_idx)[0]

    # for kk in range(0,np.size(valid_XTrain,0)):
        
    #     valid_name = sort_trial_cell[sel_other_num[kk]][0]
        
    #     valid_pca_predict = bm.as_numpy(trainer_encoder.predict(\
    #           bm.asarray(valid_XTrain[kk:(kk+1),:,:]), reset_state=True))
            
    #     valid_pca_raw = bm.as_numpy(bm.asarray(\
    #                    valid_Train_pca[kk:(kk+1),:,:]))
        
        
    #     valid_pca_rmse = np.mean(np.sqrt((valid_pca_predict-valid_pca_raw)*\
    #                                (valid_pca_predict-valid_pca_raw)))
            
            
            
    #     print('valid_pca_rmse')
    #     print(valid_pca_rmse)
        
    #     valid_ys_predict = bm.as_numpy(trainer_decoder.predict(\
    #           bm.asarray(valid_Train_pca[kk:(kk+1),:,:]), reset_state=True))
            
    #     valid_ys_raw = bm.as_numpy(bm.asarray(valid_YTrain[kk:(kk+1),:,:]))
            
    #     valid_ys_rmse = np.mean(np.sqrt((valid_ys_predict-valid_ys_raw)*\
    #                                (valid_ys_predict-valid_ys_raw)))
            
            
    #     selpc = valid_pca_predict.reshape(np.size(valid_pca_predict,1),-1)
    
    #     norm_selpc = pc_norm_01(selpc)
         
    #     valid_norm_pca_predict = norm_selpc.reshape(1,\
    #                          np.size(norm_selpc,0),\
    #                              np.size(norm_selpc,1))
             
    #     valid_pca_predict = selpc.reshape(1,\
    #                          np.size(selpc,0),\
    #                              np.size(selpc,1))
            
    #     valid_ys_pca_predict = bm.as_numpy(trainer_decoder.predict(\
    #           bm.asarray(valid_pca_predict), reset_state=True))
        
    #     valid_ys_pca_rmse = np.mean(np.sqrt((valid_ys_pca_predict-valid_ys_raw)*\
    #                            (valid_ys_pca_predict-valid_ys_raw)))
            
            
    #     print('valid_ys_rmse')
    #     print(valid_ys_rmse)
    #     print('valid_ys_pca_rmse')
    #     print(valid_ys_pca_rmse)
        
    #     #% show
    #     # pca_int = 1
        
    #     # plt.subplot(611)
    #     # for m in range(48):
    #     #     plt.plot(bm.arange(18000).to_numpy(),
    #     #               bm.as_numpy(valid_XTrain)[kk, :, m]+30*m,
    #     #               '-b',lw=0.25)
    #     # plt.axis([0,18000,-300,1900])
    #     # plt.title(tempname)
        
    #     # plt.subplot(612)
    #     # for m in range(show_pc_num):
    #     #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #     #               valid_Train_pca[kk, :, m]+pca_int*m,
    #     #               "-g",
    #     #               lw=0.25)
    #     # plt.axis([0,18000,0,show_pc_num])
    #     # plt.title('valid raw pca')
        
    #     # plt.subplot(613)
    #     # for m in range(show_pc_num):
    #     #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #     #               valid_norm_pca_predict[0, :, m]+pca_int*m,
    #     #               "-r",
    #     #               lw=0.25)
    #     # plt.axis([0,18000,0,show_pc_num])
    #     # plt.title('valid predict pca')
        
    #     # plt.subplot(614)
    #     # for m in range(48):
    #     #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #     #               valid_YTrain[kk, :, m]+30*m,
    #     #               "-r",
    #     #               lw=0.25)
    #     # plt.axis([0,18000,-300,1900])
    #     # plt.title('valid Subject pose')
        
    #     # plt.subplot(615)
    #     # for m in range(48):
    #     #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #     #               valid_ys_predict[0, :, m]+30*m,
    #     #               "-r",
    #     #               lw=0.25)
    #     # plt.axis([0,18000,-300,1900])
    #     # plt.title('valid predict pose')
        
    #     # plt.subplot(616)
    #     # for m in range(48):
    #     #     plt.plot(bm.arange(18000).to_numpy()+frame_delay,
    #     #               valid_ys_pca_predict[0, :, m]+30*m,
    #     #               "-r",
    #     #               lw=0.25)
    #     # plt.axis([0,18000,-300,1900])
    #     # plt.title('valid state pca predict pose')
        
    

            
    #     # plt.show()
        
        
    #     save_valid_XTrain = bm.as_numpy(valid_XTrain)[kk, :, :].reshape(\
    #                    np.size(valid_XTrain,1),np.size(valid_XTrain,2))
    #     save_valid_Train_pca = valid_Train_pca[kk, :, :].reshape(\
    #                    np.size(valid_Train_pca,1),np.size(valid_Train_pca,2))
    #     save_valid_norm_pca_predict = valid_norm_pca_predict[0, :, :].reshape(\
    #                    np.size(valid_norm_pca_predict,1),np.size(valid_norm_pca_predict,2))
    #     save_valid_YTrain = bm.as_numpy(valid_YTrain)[kk, :, :].reshape(\
    #                    np.size(valid_YTrain,1),np.size(valid_YTrain,2))
    #     save_valid_ys_predict = valid_ys_predict[0, :, :].reshape(\
    #                    np.size(valid_ys_predict,1),np.size(valid_ys_predict,2))
    #     save_valid_ys_pca_predict = valid_ys_pca_predict[0, :, :].reshape(\
    #                    np.size(valid_ys_pca_predict,1),np.size(valid_ys_pca_predict,2))
        
    #     save_valid_train_name = tempname + '-' + \
    #         valid_name + '-rnn_ed_valid.mat'
    #     scio.savemat(beh_neu_path + r'/' + save_valid_train_name,\
    #                   {'valid_XTrain':save_valid_XTrain,\
    #                    'valid_Train_pca':save_valid_Train_pca,\
    #                    'valid_norm_pca_predict':save_valid_norm_pca_predict,\
    #                    'valid_YTrain':save_valid_YTrain,\
    #                    'valid_ys_predict':save_valid_ys_predict,\
    #                    'valid_ys_pca_predict':save_valid_ys_pca_predict,\
    #                    })
            
    #     print('save')
    #     print(save_valid_train_name)
    
    
    
    
    
    
    
    
    
















































    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
# -*- coding: utf-8 -*-
"""
Created on Mon Oct 28 11:29:29 2024

@author: yhan
"""


import os
import pickle
import copy

import autograd.numpy as np
import autograd.numpy.random as npr
npr.seed(12345)

import matplotlib.pyplot as plt
from matplotlib import gridspec

import seaborn as sns
color_names = ["windows blue", "red", "amber", "faded green"]
colors = sns.xkcd_palette(color_names)
sns.set_style("white")
sns.set_context("talk")

import ssm
from ssm.util import random_rotation, find_permutation
import scipy.io as scio
from tqdm import tqdm
from sklearn.decomposition import PCA

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
    
    norm_selpc = (selpc-min_selpc)/(max_selpc-min_selpc)
    
    return norm_selpc

def plot_most_likely_dynamics(model,
    xlim=(-4, 4), ylim=(-3, 3), nxpts=20, nypts=20,
    alpha=0.8, ax=None, figsize=(3, 3)):
    
    K = model.K
    assert model.D == 2
    x = np.linspace(*xlim, nxpts)
    y = np.linspace(*ylim, nypts)
    X, Y = np.meshgrid(x, y)
    xy = np.column_stack((X.ravel(), Y.ravel()))

    # Get the probability of each state at each xy location
    z = np.argmax(xy.dot(model.transitions.Rs.T) + model.transitions.r, axis=1)

    if ax is None:
        fig = plt.figure(figsize=figsize)
        ax = fig.add_subplot(111)

    for k, (A, b) in enumerate(zip(model.dynamics.As, model.dynamics.bs)):
        dxydt_m = xy.dot(A.T) + b - xy

        zk = z == k
        if zk.sum(0) > 0:
            ax.quiver(xy[zk, 0], xy[zk, 1],
                      dxydt_m[zk, 0], dxydt_m[zk, 1],
                      color=colors[k % len(colors)], alpha=alpha)

    ax.set_xlabel('$x_1$')
    ax.set_ylabel('$x_2$')

    plt.tight_layout()

    return ax

def plot_most_likely_dynamics_recurrent(model,
    xlim=(-4, 4), ylim=(-3, 3), nxpts=20, nypts=20,
    alpha=0.8, ax=None, figsize=(3, 3)):
    
    K = model.K
    assert model.D == 2
    x = np.linspace(*xlim, nxpts)
    y = np.linspace(*ylim, nypts)
    X, Y = np.meshgrid(x, y)
    xy = np.column_stack((X.ravel(), Y.ravel()))

    # Get the probability of each state at each xy location
    z = np.argmax(xy.dot(model.transitions.Rs.T), axis=1)

    if ax is None:
        fig = plt.figure(figsize=figsize)
        ax = fig.add_subplot(111)

    for k, (A, b) in enumerate(zip(model.dynamics.As, model.dynamics.bs)):
        dxydt_m = xy.dot(A.T) + b - xy

        zk = z == k
        if zk.sum(0) > 0:
            ax.quiver(xy[zk, 0], xy[zk, 1],
                      dxydt_m[zk, 0], dxydt_m[zk, 1],
                      color=colors[k % len(colors)], alpha=alpha)

    ax.set_xlabel('$x_1$')
    ax.set_ylabel('$x_2$')

    plt.tight_layout()

    return ax
#%% set path
rootpath = r'H:\MTPM_body_language'
beh_neu_path = rootpath + r'\beh_neu_20240412'
savepath = rootpath + r'\dynamic_model_data_20241113'
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
    
    tempseqself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-seq-tpm.mat')
        
    ttseqself = tempseqself['seq_label_list']
        
    tempseqspartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-seq-free.mat')
        
    ttseqpartner = tempseqspartner['seq_label_list']
    
    tempdist = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-distance-free.mat')
        
    ttdist = np.vstack(tempdist['dist_data'][:,1])
    
    

    all_data_cell.append([
        ttneu,
        ttposeself,
        ttposepartner,
        ttmovself,
        ttmovpartner,
        ttseqself,
        ttseqpartner,
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
    tempdist = all_data_cell[k][7]
    
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

    newname = all_data_cell[k][8] + '-cut'
    
    
    all_data_1 = all_data_cell[k][0][tempstart:tempend, :]
    all_data_2 = all_data_cell[k][1][tempstart:tempend, :]
    all_data_3 = all_data_cell[k][2][tempstart:tempend, :]
    all_data_4 = all_data_cell[k][3][tempstart:tempend, :]
    all_data_5 = all_data_cell[k][4][tempstart:tempend, :]
    all_data_6 = all_data_cell[k][5][tempstart:tempend, :]
    all_data_7 = all_data_cell[k][6][tempstart:tempend, :]
    all_data_8 = all_data_cell[k][7][tempstart:tempend, :]
    raw_trial_cell.append([\
       newname, all_data_1, all_data_2, all_data_3, all_data_4, 
       all_data_5, all_data_6, all_data_7, 
       all_data_8, all_data_cell[k][0]])
        
    trial_length.append(np.size(all_data_1,0))

#%% calculate unique mov and unique seq
all_mov = []
for k in range(len(raw_trial_cell)):
    #%
    tempmovself = raw_trial_cell[k][4]
    tempmovpartner = raw_trial_cell[k][5]
    all_mov.append(tempmovself)
    all_mov.append(tempmovpartner)
    
all_mov = np.vstack(all_mov)

unique_mov = np.unique(all_mov)

all_seq = []
for k in range(len(raw_trial_cell)):
    #%
    tempseqself = raw_trial_cell[k][6]
    tempseqpartner = raw_trial_cell[k][7]
    all_seq.append(tempseqself)
    all_seq.append(tempseqpartner)
    
all_seq = np.vstack(all_seq)

unique_seq = np.unique(all_seq)
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
        
#%% cut trials in to far 
# far start 5s, close dynamic, far end 5s
close_baseline_time = 1
close_after_time = 0
far_min_time = 5

# smo_win_size = 5

sel_pc_num = 150#150，只塞10个状态不对，还是得150

close_baseline_frame = close_baseline_time*fs
close_after_frame = close_after_time*fs
far_min_frame = far_min_time*fs
 
far_sort_trial_cell = []
for k in range(len(sort_trial_cell)):
    #%
    dist_data = sort_trial_cell[k][8]
    distsavelist = idx2savelist(dist_data)
    
    diff_len = distsavelist[:,1]-distsavelist[:,0]+1
    
    far_min_idx = diff_len>=far_min_frame
    far_idx = distsavelist[:,2]==0
    
    diff_start = np.hstack([0,np.diff(distsavelist[:,0])])
    
    diff_start_idx = diff_start>=close_baseline_frame
    
    diff_end = np.hstack([np.diff(distsavelist[:,1]),0])
    
    diff_end_idx = diff_end>=close_after_frame
    
    selidx = (far_min_idx&far_idx)&(diff_start_idx&diff_end_idx)
    
    sel_distsavelist = distsavelist[selidx,:]
    
    new_savelist = np.vstack([\
          sel_distsavelist[:,0]-close_baseline_frame,\
          sel_distsavelist[:,1]+close_after_frame]).transpose()
        
    new_idx_list = np.zeros(np.size(dist_data))
    for m in range(np.size(new_savelist,0)):
        new_idx_list[new_savelist[m,0]:new_savelist[m,1]] = 1
        
    new_idx_list = new_idx_list==1
        
        
    all_data_1 = sort_trial_cell[k][1][new_idx_list, :]
    all_data_2 = sort_trial_cell[k][2][new_idx_list, :]
    all_data_3 = sort_trial_cell[k][3][new_idx_list, :]
    all_data_4 = sort_trial_cell[k][4][new_idx_list, :]
    all_data_5 = sort_trial_cell[k][5][new_idx_list, :]
    all_data_6 = sort_trial_cell[k][6][new_idx_list, :]
    all_data_7 = sort_trial_cell[k][7][new_idx_list, :]
    all_data_8 = sort_trial_cell[k][8][new_idx_list, :]
    
    #% normalize PCA
    
    all_data_9 = []
    for m in range(np.size(new_savelist,0)):
        tempneu = \
            sort_trial_cell[k][1][new_savelist[m,0]:new_savelist[m,1], :]
        
        pca = PCA()
        
        X_pca = pca.fit_transform(tempneu)
          
        normpca = pc_norm_01(X_pca)
        
        all_data_9.append(normpca[:,0:sel_pc_num])
        
    all_data_9 = np.vstack(all_data_9)
    
    #% smooth
    # for m in range(np.size(all_data_9,1)):
    #     tempdata = all_data_9[:,m]
    #     smodata = np.convolve(tempdata,\
    #               np.ones(smo_win_size)/smo_win_size,\
    #               mode='same')
    #     all_data_9[:,m] = smodata 
        
            
    
    far_sort_trial_cell.append([\
       sort_trial_cell[k][0], all_data_1, \
           all_data_2, all_data_3, all_data_4, 
       all_data_5, all_data_6, all_data_7, 
       all_data_8,all_data_9])
        
    # #% temp show
    # plt.plot(all_data_8)
    # plt.show()
#%% pca
pca_cell = []

for k in tqdm(range(len(far_sort_trial_cell))):
    tempdata = far_sort_trial_cell[k]
    tempneu = tempdata[1]
    
    pca = PCA()
    
    X_pca = pca.fit_transform(tempneu)
    
    pca_cell.append(X_pca)
    
#%% prepare pca dataset
sel_pc_num = 150#150，只塞10个状态不对，还是得150

pca_train = []

for temppc in pca_cell:
    selpc = temppc[:,0:sel_pc_num]
    
    # norm_selpc = pc_norm_01(selpc)#不能归一化，归一化之后学不出来
    
    pca_train.append(selpc)

#%% sort data according to brain area
brain_trial_cell = []
brain_area = ['tpmss','tpmpfc','tpmm']

for tempname in brain_area:
    new_brain_pc = []
    new_dist = []
    for k in range(len(sort_brain_name_list)):
        ttname = sort_brain_name_list[k]
        if ttname[1::] == tempname:
            selpc = far_sort_trial_cell[k][9]
            seldist = far_sort_trial_cell[k][8]
            new_brain_pc.append(selpc)
            new_dist.append(seldist)
    new_brain_pc = np.vstack(new_brain_pc)
    new_dist = np.vstack(new_dist)
    
    
    brain_trial_cell.append([new_brain_pc,new_dist])
    
#%% batch processing
for k in range(len(brain_trial_cell)):
    #%
    #% use different z to estimate the force
    #% fit to distance, two states distance
    npr.seed(12345)
    
    sel_data_idx = k
    
    y = brain_trial_cell[sel_data_idx][0]
    
    # y = pca_train[sel_data_idx]
    
    D_obs = np.size(y,1) # number of observed dimensions
    K = 2 # number of discrete states
    D_latent = 2 # number of latent dimensions
    
    rslds_dist = ssm.SLDS(D_obs, K, D_latent,
                 transitions="recurrent_only",
                 dynamics="diagonal_gaussian",
                 emissions="gaussian_orthog",
                 single_subspace=True)
    
    
    # y = pca_train[sel_data_idx][:,0:D_obs]
    
    
    
    rslds_dist.initialize(y)
    
    q_dist_elbos_lem, q_dist_lem = rslds_dist.fit(y, \
            method="laplace_em",
            variational_posterior="structured_meanfield",
            initialize=False, 
            num_iters=500, alpha=0.0)
    
    # q_dist_elbos_lem, q_dist_lem = rslds_dist.fit(y, \
    #         method="bbvi",
    #         variational_posterior="meanfield",
    #         initialize=False, 
    #         num_iters=10000, alpha=0.0)
    
    
    #% Plot some results
    plt.subplot(2,2,4)
    plt.plot(q_dist_elbos_lem[1:], label="Laplace-EM")
    plt.legend()
    plt.xlabel("Iteration")
    plt.ylabel("ELBO")
    # plt.show()
    
    xhat_dist_lem = q_dist_lem.mean_continuous_states[0]
    # xhat_dist_lem = q_dist_lem.mean[0]
    
    plt.subplot(2,2,1)
    plt.plot(y[:,0],y[:,1],'-b')
    plt.title(k)
    plt.subplot(2,2,2)
    plt.plot(xhat_dist_lem[:,0],xhat_dist_lem[:,1],'--r')
    plt.title(far_sort_trial_cell[sel_data_idx][0])
    # plt.show()
    
    #% z = close / far
    try:
        z_dist = np.int32(brain_trial_cell[sel_data_idx][1].flatten())
        
        ms_state = rslds_dist.most_likely_states(xhat_dist_lem, y)
        
        rslds_dist.permute(find_permutation(z_dist, \
                   ms_state))
        
        z_dist_hat_lem = rslds_dist.most_likely_states(xhat_dist_lem, y)
        
        plt.subplot(2,2,3)
        plt.plot(z_dist,'b')
        plt.plot(z_dist_hat_lem,'--r')
        plt.show()
    except:
        plt.subplot(2,2,3)
        plt.plot(z_dist,'b')
        plt.plot(ms_state,'--r')
        plt.show()
        
    #% show flow field
    lim = abs(xhat_dist_lem).max(axis=0) + 1
    plot_most_likely_dynamics(rslds_dist, \
      xlim=(-lim[0], lim[0]), ylim=(-lim[1], lim[1]))
    # plot_most_likely_dynamics_recurrent(rslds_dist, \
    #   xlim=(-lim[0], lim[0]), ylim=(-lim[1], lim[1]))
    plt.title([k,brain_area[sel_data_idx]])
    plt.show()
    
    #% save
    rslds_cell = {
      'q_dist_elbos_lem':q_dist_elbos_lem,
      'xhat_dist_lem':xhat_dist_lem,
      'z_dist':z_dist,
      'ms_state':ms_state,
      'model_transitions_s_T':rslds_dist.transitions.Rs.T,
      'model_transitions_r':rslds_dist.transitions.r,
      'model_dynamics_As':rslds_dist.dynamics.As,
      'model_dynamics_bs':rslds_dist.dynamics.bs
      }
    
    
    savepathname = savepath + r'/' + \
        brain_area[sel_data_idx] + r'_close_far_20241113.mat'
        
        
    scio.savemat(savepathname,rslds_cell)
    















































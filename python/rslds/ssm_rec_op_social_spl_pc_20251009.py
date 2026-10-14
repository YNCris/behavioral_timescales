# -*- coding: utf-8 -*-
"""
Created on Wed Oct  8 17:20:18 2025

@author: dell
"""

#%%
import matplotlib.pyplot as plt

import os

import scipy.io as scio
from tqdm import tqdm
import numpy as np

import autograd.numpy.random as npr
npr.seed(12345)

from sklearn.decomposition import PCA

import ssm
from ssm.util import random_rotation, find_permutation
import scipy.io as scio
from tqdm import tqdm

import seaborn as sns
color_names = ["windows blue", "red", "amber", "faded green"]
colors = sns.xkcd_palette(color_names)
sns.set_style("white")
sns.set_context("talk")

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
#%% 1. Create or load your dataset
#dataset = TensorDataset(data=torch.randn(100, 50))

rootpath = r'H:\MTPM_body_language'

beh_video_path = rootpath + r'\raw_data\behavior_op_20250915'

bea_path = beh_video_path + r'\BeA_path'

sep_tpm_path = rootpath + r'\raw_data\tpm_suite2p\sep'

beh_neu_path = rootpath + r'\beh_neu_20250918'

savepath = beh_neu_path

files = os.listdir(beh_neu_path)

rootnames = []
for file in files:
    #%
    splname = file.split('-')
    if splname[-1] == 'neu.mat':
        rootnames.append(file)

cut_size = 900

all_data_cell = []
for rootname in tqdm(rootnames):
    #%
    temprootname = rootname[0:-8]
    
    tempneu = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-neu.mat')
        
    ttneu = tempneu['dff_smo_Fc'].transpose()[cut_size::,:]
    
    tempposeself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-pose-tpm.mat')
        
    ttposeself = tempposeself['coords3d'][cut_size::,:]
    
    tempposepartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-pose-free.mat')
        
    ttposepartner = tempposepartner['coords3d'][cut_size::,:]
    
    tempmovself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-beh_mod-tpm.mat')

    ttmovself = np.vstack(tempmovself['beh_mod_list'][:,1])[cut_size::,:]
    
    tempmovpartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-beh_mod-free.mat')

    ttmovpartner = np.vstack(tempmovpartner['beh_mod_list'][:,1])[cut_size::,:]
    
    tempseqself = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-seq-tpm.mat')
        
    ttseqself = tempseqself['seq_label_list'][cut_size::,:]
        
    tempseqspartner = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-seq-free.mat')
        
    ttseqpartner = tempseqspartner['seq_label_list'][cut_size::,:]
    
    tempdist = scio.loadmat(\
       beh_neu_path + r'/' + temprootname + r'-distance-free.mat')
        
    ttdist = np.vstack(tempdist['dist_data'][:,1])[cut_size::,:]
    
    

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
    
#%% cut trials in to far close far
# far start 5s, close dynamic, far end 5s
far_baseline_time = 2
far_after_time = 2
close_min_time = 2
close_max_time = 4

fs = 30

# smo_win_size = 5

sel_pc_num = 25#150，只塞10个状态不对，还是得150

far_baseline_frame = far_baseline_time*fs
far_after_frame = far_after_time*fs
close_min_frame = close_min_time*fs
close_max_frame = close_max_time*fs
 
close_sort_trial_cell = []
for k in range(len(all_data_cell)):
    #%
    dist_data = all_data_cell[k][7]
    distsavelist = idx2savelist(dist_data)
    
    diff_len = distsavelist[:,1]-distsavelist[:,0]+1
    
    close_min_idx = diff_len>=close_min_frame
    close_max_idx = diff_len<=close_max_frame
    close_idx = distsavelist[:,2]==1
    
    diff_start = np.hstack([0,np.diff(distsavelist[:,0])])
    
    diff_start_idx = diff_start>=(far_baseline_frame*2)
    
    diff_end = np.hstack([np.diff(distsavelist[:,1]),0])
    
    diff_end_idx = diff_end>=far_after_frame
    
    selidx = ((close_min_idx&close_max_idx)&close_idx)&(diff_start_idx&diff_end_idx)
    
    sel_distsavelist = distsavelist[selidx,:]
    
    new_savelist = np.vstack([\
          sel_distsavelist[:,0]-far_baseline_frame,\
          sel_distsavelist[:,1]+far_after_frame]).transpose()
        
    new_idx_list = np.zeros(np.size(dist_data))
    for m in range(np.size(new_savelist,0)):
        new_idx_list[new_savelist[m,0]:new_savelist[m,1]] = 1
        
    new_idx_list = new_idx_list==1
        
        
    all_data_1 = all_data_cell[k][0][new_idx_list, :]
    all_data_2 = all_data_cell[k][1][new_idx_list, :]
    all_data_3 = all_data_cell[k][2][new_idx_list, :]
    all_data_4 = all_data_cell[k][3][new_idx_list, :]
    all_data_5 = all_data_cell[k][4][new_idx_list, :]
    all_data_6 = all_data_cell[k][5][new_idx_list, :]
    all_data_7 = all_data_cell[k][6][new_idx_list, :]
    all_data_8 = all_data_cell[k][7][new_idx_list, :]
    
    #% normalize PCA
    
    all_data_9 = []
    for m in range(np.size(new_savelist,0)):
        tempneu = \
            all_data_cell[k][0][new_savelist[m,0]:new_savelist[m,1], :]
        
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
        
            
    
    close_sort_trial_cell.append([\
       all_data_cell[k][8], all_data_1, \
           all_data_2, all_data_3, all_data_4, 
       all_data_5, all_data_6, all_data_7, 
       all_data_8,all_data_9])
        
    # #% temp show
    # plt.plot(all_data_8)
    # plt.show()
    
    print(np.size(all_data_8,0)-np.size(all_data_9,0))

#%% connect rec & rec+op, separately
con_idx_mat = [
    [0,1,2,3,4],
    [6,7,8,9,5],
    ]

spl_dim = 10

raw_dataset = []
for k in range(len(con_idx_mat)):
    tempcon = con_idx_mat[k]
    
    tempconmat = []
    tempcondist = []
    for m in range(len(tempcon)):
        selpca = close_sort_trial_cell[tempcon[m]][9]
        seldist = close_sort_trial_cell[tempcon[m]][8]
        tempconmat.append(selpca)
        tempcondist.append(seldist)

    con_pca = np.vstack(tempconmat)
    con_dist = np.vstack(tempcondist)
    
    low_con_pca = con_pca[:,0:spl_dim]
    low_con_dist = con_dist
    
    high_con_pca = con_pca[:,(sel_pc_num-spl_dim)::]
    high_con_dist = con_dist
    
    raw_dataset.append([low_con_pca,low_con_dist])
    raw_dataset.append([high_con_pca,high_con_dist])
    
#%% batch processing
save_name_list = [
    'rec_low',
    'rec_high',
    'rec_op_low',
    'rec_op_high']


for k in range(len(raw_dataset)):
    #%
    #% use different z to estimate the force
    #% fit to distance, two states distance
    npr.seed(12345)
    
    sel_data_idx = k
    
    y = raw_dataset[sel_data_idx][0]
    
    # y = pca_train[sel_data_idx]
    
    D_obs = np.size(y,1) # number of observed dimensions
    K = 2 # number of discrete states，先试试3，间隔一个，光遗传前后各一个
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
            num_iters=1000, alpha=0.0)
    
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
    # plt.show()
    
    #% z = close / far
    try:
        z_dist = np.int32(raw_dataset[sel_data_idx][1])
        
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
    plt.title(k)
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
        save_name_list[k] + r'_social_20251009.mat'
        
        
    scio.savemat(savepathname,rslds_cell)  
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
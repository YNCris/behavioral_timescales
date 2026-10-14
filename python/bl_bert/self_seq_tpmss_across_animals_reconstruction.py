'''
build up low dimensional embeddings 
'''
import sys

import matplotlib.pyplot as plt
import cebra.data
import cebra.datasets
import cebra.integrations
from cebra import CEBRA
import matplotlib.pyplot as plt
import pickle
import joblib as jl
import torch
import h5py
import numpy as np
from tqdm import tqdm
import scipy.io as scio
import os
import copy

def file_name(file_dir,fileformat):
  L=[]
  for root, dirs, files in os.walk(file_dir):
    for file in files:
      if os.path.splitext(file)[1] == fileformat:
        L.append(os.path.join(root, file))
  return L
#%%
rootpath = '/g/rompani/hanyaning/project_siat/body_language/beh_neu_20240412'
savepath = rootpath + '/cebra'

if not os.path.exists(savepath):
    os.mkdir(savepath)
#%% load pose and tpmm data
exp_cond = 'free'
brain_area = 'tpmss'
beh_type = 'seq'
mouse_type = 'tpm'

all_names = os.listdir(rootpath)

sel_name_list = []
for tempname in all_names:
    #% splname
    splname = tempname.split('-')
    if len(splname) == 7:
        name_seg_exp_cond = splname[0]
        name_brain_area = splname[2][1:]
        name_beh_type = splname[5]
        name_mouse_type = splname[6][0:-4]
        #% select names
        if name_seg_exp_cond == exp_cond and \
                name_brain_area == brain_area and \
                name_beh_type == beh_type and \
                name_mouse_type == mouse_type:
            neu_tempname = tempname[0:-12] + '-neu.mat'
            sel_name_list.append([tempname,neu_tempname])
            print(tempname)

# load data
neu_data_list = []
beh_data_list = []
for tempname in tqdm(sel_name_list):
    #% load names
    tempbehname = tempname[0]
    tempneuname = tempname[1]
    #% load data
    tempbehdata = scio.loadmat(rootpath + '/' + tempbehname)
    tempneudata = scio.loadmat(rootpath + '/' + tempneuname)
    #% append data
    neu_data_list.append(tempneudata['dff_smo_Fc'].transpose())
    beh_data_list.append(np.float64(tempbehdata['seq_label_list']))
#%% reshape data
datas = neu_data_list.copy()
labels = beh_data_list.copy()

#%% load embeddings
#% Transform each session with the right model, by providing the corresponding session ID
multi_embeddings = []
for i in range(len(datas)):
    tempbehname = sel_name_list[i][0]
    temprootname = tempbehname[0:-4]

    tempsavename = temprootname + "-cebra.mat"

    tempdata = scio.loadmat(rootpath + '/' + tempsavename)

    multi_embeddings.append(tempdata['cebra'])

#%% fit cebra knn decoder, prediction, and calculate the reconstruction error
cebra_decoder_list = []
decode_list = []
error_list = []
error_list_all = []

train_time = 9000
for i in tqdm(range(len(datas))):
    #%
    cebra_decoder = cebra.KNNDecoder(n_neighbors=1,metric="cosine")
    cebra_decoder.fit(multi_embeddings[i][0:train_time,:], labels[i][0:train_time])

    cebra_pred = cebra_decoder.predict(multi_embeddings[i])

    tempdata = labels[i]
    tempdist = np.int32((tempdata[train_time::] - cebra_pred[train_time::])!=0)

    mean_dist = np.mean(tempdist)
    #% append data

    cebra_decoder_list.append(copy.deepcopy(cebra_decoder))
    decode_list.append(copy.deepcopy(cebra_pred))

    error_list.append(mean_dist)

    error_list_all.append(tempdist)

#%% save to mat
for k in tqdm(range(len(sel_name_list))):
    tempbehname = sel_name_list[k][0]
    temprootname = tempbehname[0:-4]

    tempsavename = temprootname + "-reconstruction_error.mat"

    save_mat_data = {
        'decode_pred': decode_list[k],
        'dist_error': error_list[k],
        'dist_error_all': error_list_all[k]}
    scio.savemat(rootpath + '/' + tempsavename,save_mat_data)

    print('save')
    print(tempsavename)








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
#%% preprocess

#%% train model
datas = neu_data_list.copy()
labels = beh_data_list.copy()

max_iterations = 15000

# single session training, cebra cannot be used in the 离散时间多动物
cebra_model_list = []

for m in range(len(datas)):
    multi_cebra_model = CEBRA(model_architecture='offset10-model',
                        batch_size=1024,
                        learning_rate=3e-4,
                        temperature=1,
                        output_dimension=3,
                        max_iterations=max_iterations,
                        distance='cosine',
                        conditional='time_delta',
                        device='cuda',
                        verbose=True,
                        time_offsets=10)

    # Provide a list of data, i.e. datas = [data_a, data_b, ...]
    multi_cebra_model.fit(datas[m], labels[m])

    tempname = sel_name_list[m][0][0:-16]

    multi_cebra_model.save(savepath + "/cebra_model_" + \
                           exp_cond + "_" + brain_area + \
                           "_" + beh_type + "_" + mouse_type + \
                           "_" + tempname + ".pt")

    cebra_model_list.append(multi_cebra_model)

    print('save')
    print(m)
#%% Transform each session with the right model, by providing the corresponding session ID
multi_embeddings = []
for i in range(len(datas)):
    X = datas[i]
    multi_embeddings.append(cebra_model_list[i].transform(X))

#%% save data
for k in tqdm(range(len(sel_name_list))):
    tempbehname = sel_name_list[k][0]
    temprootname = tempbehname[0:-4]

    tempsavename = temprootname + "-cebra.mat"

    save_mat_data = {'cebra': multi_embeddings[k]}
    scio.savemat(rootpath + '/' + tempsavename,save_mat_data)

    print('save')
    print(tempsavename)










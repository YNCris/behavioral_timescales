'''
Mapping far to close
Reference: (to be predicted):
self_close_neu
self_close_pose
self_close_mov
self_close_seq

Sources:
self_far_neu
self_far_pose
self_far_mov
self_far_seq
partner_far_pose
partner_far_mov
partner_far_seq
partner_close_pose
partner_close_mov
partner_close_seq

Scientific question:

Which source can predict the references?
'''
#%% import

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
#%% set path
rootpath = '/g/rompani/hanyaning/project_siat/body_language/beh_neu_20240412'
#%% load data
cebraNames = os.listdir(rootpath + '/free*cebra.mat')

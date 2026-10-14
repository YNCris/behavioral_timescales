#!/bin/bash

#SBATCH -J yhan
#SBATCH -A rompani

#SBATCH -n 1
#SBATCH -N 1
#SBATCH -t 240:00:00
#SBATCH --mem=100G
#SBATCH --verbose
#SBATCH --output /g/rompani/hanyaning/slurm_%x_%A_%a.out

cd /home/yhan/code/python/cebra_body_language

#srun hostname   | sort

srun self_seq_tpmss_across_animals_reconstruction.py
srun self_seq_tpmpfc_across_animals_reconstruction.py
srun self_seq_tpmm_across_animals_reconstruction.py
srun self_pose_tpmss_across_animals_reconstruction.py
srun self_pose_tpmpfc_across_animals_reconstruction.py
srun self_pose_tpmm_across_animals_reconstruction.py
srun self_beh-mod_tpmss_across_animals_reconstruction.py
srun self_beh-mod_tpmpfc_across_animals_reconstruction.py
srun self_beh-mod_tpmm_across_animals_reconstruction.py
srun partner_seq_tpmss_across_animals_reconstruction.py
srun partner_seq_tpmpfc_across_animals_reconstruction.py
srun partner_seq_tpmm_across_animals_reconstruction.py
srun partner_pose_tpmss_across_animals_reconstruction.py
srun partner_pose_tpmpfc_across_animals_reconstruction.py
srun partner_pose_tpmm_across_animals_reconstruction.py
srun partner_beh-mod_tpmss_across_animals_reconstruction.py
srun partner_beh-mod_tpmpfc_across_animals_reconstruction.py
srun partner_beh-mod_tpmm_across_animals_reconstruction.py

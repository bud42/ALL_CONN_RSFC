mkdir /nobackup/h_taylor/TEST-all_conn_rsfc
mkdir /nobackup/h_taylor/TEST-all_conn_rsfc/INPUTS
mkdir /nobackup/h_taylor/TEST-all_conn_rsfc/OUTPUTS
mkdir /nobackup/h_taylor/TEST-all_conn_rsfc/OUTPUTS/PREPROC
mkdir /nobackup/h_taylor/TEST-all_conn_rsfc/OUTPUTS/ROI


for i in *;do cp /data/Newhouse/Imaging/CHAMP_NonDrug21_RSFC/PREPROC/$i/ANAT.nii $i;done
for i in *;do cp /data/Newhouse/Imaging/CHAMP_NonDrug21_RSFC/PREPROC/$i/REST1.nii $i;done
for i in *;do cp /data/Newhouse/Imaging/CHAMP_NonDrug21_RSFC/PREPROC/$i/REST2.nii $i;done

# Must run from OUTPUTS 
cd /nobackup/h_taylor/TEST-all_conn_rsfc/OUTPUTS

echo "Running singularity"
singularity run /data/h_taylor/Imaging/SINGULARITY_IMAGES/all_conn_rsfc_v1.0.0.sif

cd /INPUTS

for i in *;do
    mkdir -p /OUTPUTS/DATA/PREPROC/$i/FMRI/Baseline
    cp $i/Baseline-ANAT.nii.gz /OUTPUTS/DATA/PREPROC/$i/ANAT.nii.gz
    cp $i/Baseline-REST1.nii.gz /OUTPUTS/DATA/PREPROC/$i/FMRI/Baseline/REST1.nii.gz
    cp $i/Baseline-REST2.nii.gz /OUTPUTS/DATA/PREPROC/$i/FMRI/Baseline/REST2.nii.gz
    gunzip /OUTPUTS/DATA/PREPROC/*/FMRI/*/*.nii.gz
    gunzip /OUTPUTS/DATA/PREPROC/*/*.nii.gz
done

echo networks.DefaultMode networks.Salience networks.FrontoParietal > /OUTPUTS/DATA/sources.txt

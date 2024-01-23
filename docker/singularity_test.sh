if [ -d "$HOME/TEST-all_conn_rsfc" ]; then
    echo "Already exists, delete first"
    exit 1;
fi

echo "Downloading inputs"

mkdir $HOME/TEST-all_conn_rsfc
mkdir $HOME/TEST-all_conn_rsfc/INPUTS
mkdir $HOME/TEST-all_conn_rsfc/OUTPUTS

# TODO:Download

echo "Running singularity"
singularity run \
-B $HOME/TEST-all_conn_rsfc/INPUTS:/INPUTS \
-B $HOME/TEST-all_conn_rsfc/OUTPUTS:/OUTPUTS \
/data/h_taylor/Imaging/SINGULARITY_IMAGES/all_conn_rsfc_v1.sif


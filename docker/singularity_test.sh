if [ -d "/tmp/TEST-all_conn_rsfc" ]; then
    echo "Already exists, delete first"
    exit 1;
fi

echo "Downloading inputs"

mkdir /tmp/TEST-all_conn_rsfc
mkdir /tmp/TEST-all_conn_rsfc/INPUTS
mkdir /tmp/TEST-all_conn_rsfc/OUTPUTS

# TODO:Download

echo "Running singularity"
singularity run \
-B /tmp/TEST-all_conn_rsfc/INPUTS:/INPUTS \
-B /tmp/TEST-all_conn_rsfc/OUTPUTS:/OUTPUTS \
/data/h_taylor/Imaging/SINGULARITY_IMAGES/all_conn_rsfc_v1.sif

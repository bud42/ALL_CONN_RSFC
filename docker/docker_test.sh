
if [ -d "$HOME/TEST-all_conn_rsfc" ]; then
    echo "Already exists, delete first"
    exit 1;
fi

echo "Downloading inputs"



echo "Running docker"
docker run \
--platform linux/amd64 \
-it --rm \
-v $HOME/TEST-all_conn_rsfc/INPUTS:/INPUTS \
-v $HOME/TEST-all_conn_rsfc/OUTPUTS:/OUTPUTS \
bud42/all_conn_rsfc:v1.0.0


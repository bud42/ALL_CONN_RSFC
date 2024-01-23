docker run \
--platform linux/amd64 \
-ti \
--rm \
--entrypoint /bin/bash \
-v ~/TEST-all_conn_rsfc/INPUTS:/INPUTS \
-v ~/TEST-all_conn_rsfc/OUTPUTS:/OUTPUTS \
bud42/all_conn_rsfc:v1.0.0


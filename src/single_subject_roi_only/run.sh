echo "Running CONN Pipeline"
xvfb-run \
-e /OUTPUTS/xvfb.err -f /OUTPUTS/xvfb.auth \
-a --server-args "-screen 0 1600x1200x24" \
/opt/conn/run_conn.sh /opt/matlabruntime/v912 batch /opt/src/single_subject_roi_only/main.m
rm /OUTPUTS/xvfb.auth /OUTPUTS/xvfb.err

echo "ALL DONE!"

echo "Running CONN Pipeline single subject without slice time correction"
xvfb-run \
-e /OUTPUTS/xvfb.err -f /OUTPUTS/xvfb.auth \
-a --server-args "-screen 0 1600x1200x24" \
/opt/conn/run_conn.sh /opt/matlabruntime/v912 batch /opt/src/single_subject_no_stc/main.m
rm /OUTPUTS/xvfb.auth /OUTPUTS/xvfb.err

echo "ALL DONE!"

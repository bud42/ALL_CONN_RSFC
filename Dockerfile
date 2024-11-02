FROM containers.mathworks.com/matlab-runtime:r2022a

ENV AGREE_TO_MATLAB_RUNTIME_LICENSE=yes

# Install CONN Standalone
COPY conn22a_glnxa64.zip /opt/conn22a_glnxa64.zip
RUN unzip -qj /opt/conn22a_glnxa64.zip -d /opt/conn && \
    /opt/conn/run_conn.sh /opt/matlabruntime/v912 batch exit && \
    rm -f /opt/conn22a_glnxa64.zip

# Install our code
COPY ROI /opt/ROI/
COPY src /opt/src/
RUN chmod a+x /opt/src/*.sh

# Set our default command to run
ENTRYPOINT ["/bin/bash", "/opt/src/run.sh"]

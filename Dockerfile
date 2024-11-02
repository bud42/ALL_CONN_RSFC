FROM containers.mathworks.com/matlab-runtime:r2022a

ENV AGREE_TO_MATLAB_RUNTIME_LICENSE=yes

# Install CONN Standalone
COPY conn22a_glnxa64.zip /opt/conn22a_glnxa64.zip
RUN unzip -qj /opt/conn22a_glnxa64.zip -d /opt/conn && \
    /opt/conn/run_conn.sh /opt/matlabruntime/v912 batch exit && \
    rm -f /opt/conn22a_glnxa64.zip

RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq --no-install-recommends \
    openssh-client \
    apt-utils ca-certificates zip unzip xorg wget xvfb \
    bc libgomp1 libxmu6 libxt6 libstdc++6 tar \
    ghostscript libgs-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod 777 /opt && chmod a+s /opt

# Install our code
COPY ROI /opt/ROI/
COPY src /opt/src/
RUN chmod a+x /opt/src/*.sh

# Set our default command to run
ENTRYPOINT ["/bin/bash", "/opt/src/run.sh"]

FROM python:3.8-slim-buster

# Install packages needed to install matlab
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq --no-install-recommends \
    openssh-client \
    apt-utils ca-certificates unzip xorg wget xvfb \
    bc libgomp1 libxmu6 libxt6 libstdc++6 tar \
    ghostscript libgs-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && chmod 777 /opt && chmod a+s /opt

# Install MATLAB MCR
ENV MCR_INHIBIT_CTF_LOCK 1
RUN mkdir /opt/mcr_install /opt/mcr
COPY MATLAB_Runtime_R2022a_Update_8_glnxa64.zip /opt/mcr_install
RUN unzip -q /opt/mcr_install/MATLAB_Runtime_R2022a_Update_8_glnxa64.zip \
    -d /opt/mcr_install && \
    /opt/mcr_install/install \
    -destinationFolder /opt/mcr \
    -agreeToLicense yes \
    -mode silent && \
    rm -rf /opt/mcr_install /tmp/*

# Install CONN Standalone
COPY conn22a_glnxa64.zip /opt/conn22a_glnxa64.zip
RUN unzip -qj /opt/conn22a_glnxa64.zip -d /opt/conn && \
    rm -f /opt/conn22a_glnxa64.zip

# Initialize CONN for Singularity purposes
RUN /opt/conn/run_conn.sh /opt/mcr/v912 batch exit

# Install our code
COPY src /opt/src/
RUN chmod a+x /opt/src/*.sh

# Set our default command to run
ENTRYPOINT ["/bin/bash", "/opt/src/run.sh"]

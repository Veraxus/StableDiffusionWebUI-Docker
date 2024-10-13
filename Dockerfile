FROM nvidia/cuda:12.6.1-cudnn-devel-ubuntu24.04

WORKDIR /app

# Install prereqs and run automatic install script
RUN apt-get update && apt-get install -y --no-install-recommends \
        bc \
        curl \
        wget \
        git \
        libgl1 \
        libglib2.0-0 \
        libtcmalloc-minimal4 \
        software-properties-common && \
        apt-get clean && \
        rm -rf /var/lib/apt/lists/*

# Set 3.10 as the default Python (SDWUI doesn't like 3.11+)
RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt install python3.10-venv -y && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    wget https://bootstrap.pypa.io/get-pip.py && python3 get-pip.py && rm get-pip.py

# Create a non-root user and switch to that user (webui doesn't allow root)
RUN useradd -m -s /bin/bash webui-user && chown -R webui-user:webui-user /app
USER webui-user

# Download & install WebUI
RUN git config --global http.postBuffer 1048576000 && \
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh)"

WORKDIR /app/stable-diffusion-webui

# Set webui venv & create repositories directory so we can make a volume with correct perms
RUN python3.10 -m venv venv && \
    mkdir repositories && \
    mkdir outputs

# Overwrite the local branch with Forge without merging
RUN git config --global http.postBuffer 1048576000 && \
    git remote add forge https://github.com/lllyasviel/stable-diffusion-webui-forge && \
    git fetch forge && \
    git checkout -B lllyasviel/main forge/main

EXPOSE 7860

# Disable the default nvidia entrypoint
#ENTRYPOINT []

# Start SDWUI
CMD ["/app/stable-diffusion-webui/webui.sh", "--xformers", "--enable-insecure-extension-access", "--listen", "--port", "7860"]
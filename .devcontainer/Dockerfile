FROM python:3.7.4-buster

ARG USERNAME=tk
# On Linux, replace with your actual UID, GID if not the default 1000
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/.vscode-server /home/$USERNAME/.vscode-server-insiders \
    && chown ${USER_UID}:${USER_GID} /home/$USERNAME/.vscode-server*

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

RUN curl -L https://releases.hashicorp.com/terraform/0.12.12/terraform_0.12.12_linux_amd64.zip -o /tmp/tf.zip; unzip /tmp/tf.zip -d /usr/local/bin/; rm /tmp/tf.zip
RUN apt update && apt install zip -y && rm -rf /var/lib/apt/lists/*

# change the username
USER $USERNAME
RUN pip install awscli --upgrade --user

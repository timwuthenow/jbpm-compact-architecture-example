FROM mcr.microsoft.com/devcontainers/java:17

# Install SDKMAN for Java version management
RUN curl -s "https://get.sdkman.io" | bash

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose

# Set up non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
	&& useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
	&& apt-get update \
	&& apt-get install -y sudo \
	&& echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
	&& chmod 0440 /etc/sudoers.d/$USERNAME

# Install additional dependencies
RUN apt-get update && apt-get install -y \
	curl \
	git \
	wget \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

USER $USERNAME

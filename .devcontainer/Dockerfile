FROM mcr.microsoft.com/devcontainers/java:17

# Install SDKMAN for Java version management
RUN bash -c ". /usr/local/sdkman/bin/sdkman-init.sh && sdk version"

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose

# Install additional dependencies
RUN apt-get update && apt-get install -y \
	curl \
	git \
	wget \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

# Switch to vscode user (already exists in base image)
USER vscode

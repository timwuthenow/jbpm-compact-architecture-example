FROM mcr.microsoft.com/devcontainers/java:17

# Install SDKMAN for Java version management
RUN bash -c ". /usr/local/sdkman/bin/sdkman-init.sh && sdk version"

# Install Maven
RUN apt-get update && apt-get install -y maven

# Create .m2 directory and settings.xml
COPY settings.xml /home/vscode/.m2/settings.xml

# Pre-populate common Maven dependencies
RUN mkdir -p /home/vscode/tmp-project && \
	cd /home/vscode/tmp-project && \
	mvn archetype:generate -DgroupId=com.example -DartifactId=pre-cache -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false && \
	mvn dependency:go-offline && \
	cd / && \
	rm -rf /home/vscode/tmp-project

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

# Add Maven to PATH
ENV PATH="/usr/share/maven/bin:${PATH}"

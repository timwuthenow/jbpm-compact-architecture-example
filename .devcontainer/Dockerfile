FROM mcr.microsoft.com/devcontainers/java:17

# Install Maven
RUN apt-get update && apt-get install -y maven

# Create Maven .m2 directory and settings
RUN mkdir -p /home/vscode/.m2 && \
	echo '<?xml version="1.0" encoding="UTF-8"?>\n\
	<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" \n\
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \n\
	xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">\n\
	<servers>\n\
	</servers>\n\
	<mirrors>\n\
	<mirror>\n\
	<id>central-secure</id>\n\
	<url>https://repo.maven.apache.org/maven2</url>\n\
	<mirrorOf>central</mirrorOf>\n\
	</mirror>\n\
	</mirrors>\n\
	</settings>' > /home/vscode/.m2/settings.xml

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/v2.24.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose \
	&& chmod +x /usr/local/bin/docker-compose

# Ensure docker group exists and add vscode user to it
RUN groupadd -f docker && usermod -aG docker vscode

# Install additional dependencies
RUN apt-get update && apt-get install -y \
	curl \
	git \
	wget \
	unzip \
	&& rm -rf /var/lib/apt/lists/*

# Set correct permissions
RUN chown -R vscode:vscode /home/vscode/.m2

# Switch to vscode user
USER vscode

# Add Maven to PATH
ENV PATH="/usr/share/maven/bin:${PATH}"

# Set MAVEN_OPTS for Java 17
ENV MAVEN_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=1024m"

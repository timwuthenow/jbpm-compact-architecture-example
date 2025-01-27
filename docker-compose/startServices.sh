#!/bin/sh

PROFILE="full"
DEFAULT_VERSION="1.0.0-SNAPSHOT"

# Check for command line argument
if [ -n "$1" ]; then
  if [[ ("$1" == "full") || ("$1" == "infra") || ("$1" == "example")]]; then
    PROFILE="$1"
  else
    echo "Unknown docker profile '$1'. The supported profiles are:"
    echo "* 'infra': Use this profile to start only the minimum infrastructure to run the example."
    echo "* 'example': Use this profile to start the example infrastructure and the kogito-example service."
    echo "* 'full' (default): Starts full example setup."
    exit 1;
  fi
fi

# Function to get Maven variables
get_maven_vars() {
    cd ..
    PROJECT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo "${DEFAULT_VERSION}")
    KOGITO_MANAGEMENT_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.management-console.image -q -DforceStdout)
    KOGITO_TASK_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.task-console.image -q -DforceStdout)
    cd - > /dev/null
}

# Get initial version for image check
get_maven_vars
IMAGE_NAME="dev.local/${USER}/jbpm-compact-architecture-example-service:${PROJECT_VERSION}"

# Check if image exists locally first
if docker image inspect "${IMAGE_NAME}" >/dev/null 2>&1; then
    # Image exists, check when it was created
    IMAGE_DATE=$(docker image inspect -f "{{.Created}}" "${IMAGE_NAME}")
    echo "Docker image exists, created on: $IMAGE_DATE"
    read -p "Do you want to rebuild? (y/N) " REBUILD_CHOICE
    if [ "${REBUILD_CHOICE}" = "y" ] || [ "${REBUILD_CHOICE}" = "Y" ]; then
        DO_BUILD=true
    else
        DO_BUILD=false
    fi
else
    echo "Docker image not found, building..."
    DO_BUILD=true
fi

# Build if needed
if [ "$DO_BUILD" = true ]; then
    cd ..
    echo "Building the project with container profile..."
    mvn clean install -DskipTests -Pcontainer
    if [ $? -ne 0 ]; then
        echo "Maven build failed"
        exit 1
    fi
    cd - > /dev/null
fi

# Get Maven variables (whether we built or not)
get_maven_vars

# Set host name for Mac/Linux
if [ "$(uname)" = "Darwin" ]; then
   BROWSER_HOST="kubernetes.docker.internal"
elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
   BROWSER_HOST="172.17.0.1"
fi

# Create .env file
cat << EOF > .env
PROJECT_VERSION=${PROJECT_VERSION}
KOGITO_MANAGEMENT_CONSOLE_IMAGE=${KOGITO_MANAGEMENT_CONSOLE_IMAGE}
KOGITO_TASK_CONSOLE_IMAGE=${KOGITO_TASK_CONSOLE_IMAGE}
COMPOSE_PROFILES=${PROFILE}
USER=${USER}
BROWSER_HOST=${BROWSER_HOST}
EOF

# Verify SVG folder exists
if [ ! -d "./svg" ]; then
    echo "SVG folder does not exist. Have you compiled the project? mvn clean install -DskipTests"
    exit 1
fi

# Start Docker Compose
docker compose up

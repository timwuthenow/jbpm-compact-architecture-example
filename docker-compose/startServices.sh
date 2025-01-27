#!/bin/sh

PROFILE="full"

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

# Check if image exists
if docker image inspect dev.local/jbpm-compact-architecture-example-service:1.0.0-SNAPSHOT >/dev/null 2>&1; then
    # Image exists, check when it was created
    IMAGE_DATE=$(docker image inspect -f "{{.Created}}" dev.local/jbpm-compact-architecture-example-service:1.0.0-SNAPSHOT)

    echo "Docker image exists, created on: $IMAGE_DATE"
    read -p "Do you want to rebuild? (y/N) " REBUILD_CHOICE

    if [ "${REBUILD_CHOICE,,}" = "y" ]; then
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
    # Get Maven project version and image names
    cd ..
    echo "Building the project with container profile..."
    mvn clean install -DskipTests -Pcontainer

    PROJECT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    KOGITO_MANAGEMENT_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.management-console.image -q -DforceStdout)
    KOGITO_TASK_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.task-console.image -q -DforceStdout)
    cd -
else
    # If we didn't build, we still need to get the variables
    cd ..
    PROJECT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
    KOGITO_MANAGEMENT_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.management-console.image -q -DforceStdout)
    KOGITO_TASK_CONSOLE_IMAGE=$(mvn help:evaluate -Dexpression=kogito.task-console.image -q -DforceStdout)
    cd -
fi

# Set host name for Mac/Linux
if [ "$(uname)" == "Darwin" ]; then
   BROWSER_HOST="kubernetes.docker.internal"
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
   BROWSER_HOST="172.17.0.1"
fi

# Create .env file
echo "PROJECT_VERSION=${PROJECT_VERSION}" > ".env"
echo "KOGITO_MANAGEMENT_CONSOLE_IMAGE=${KOGITO_MANAGEMENT_CONSOLE_IMAGE}" >> ".env"
echo "KOGITO_TASK_CONSOLE_IMAGE=${KOGITO_TASK_CONSOLE_IMAGE}" >> ".env"
echo "COMPOSE_PROFILES=${PROFILE}" >> ".env"
echo "USER=${USER}" >> ".env"
echo "BROWSER_HOST=${BROWSER_HOST}" >> ".env"

if [ ! -d "./svg" ]; then
    echo "SVG folder does not exist. Have you compiled the project? mvn clean install -DskipTests"
    exit 1
fi

docker compose up

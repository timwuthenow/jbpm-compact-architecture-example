#!/bin/bash
set -e # Exit on error

PROFILE="full"
DEFAULT_VERSION="1.0.0-SNAPSHOT"

# Ask if running in devcontainers
read -p "Are you running in devcontainers? (yes/no): " DEVCONTAINERS_RESPONSE

if [[ "$DEVCONTAINERS_RESPONSE" =~ ^[Yy] ]]; then
  echo "Running in a Dev Container setup."
  USE_CODESPACE=true
else
  echo "Running in a local Docker Compose setup."
  USE_CODESPACE=false
fi

# Extract codespace name from hostname if running in GitHub Codespace
if [ "$USE_CODESPACE" = true ]; then
    if [ -n "$CODESPACE_NAME" ]; then
        BASE_HOSTNAME="${CODESPACE_NAME}.app.github.dev"
    else
        BASE_HOSTNAME=$(echo "$HOSTNAME" | cut -d'-' -f1,2)".app.github.dev"
    fi

    # Define service-specific hostnames
    JBPM_URL="https://${BASE_HOSTNAME}-8080"
    MANAGEMENT_URL="https://${BASE_HOSTNAME}-8280"
    TASK_URL="https://${BASE_HOSTNAME}-8380"
    KEYCLOAK_URL="https://${BASE_HOSTNAME}-8480"
	POSTGRES_URL="${BASE_HOSTNAME}-5432"
else
    # Local development URLs
    JBPM_URL="http://jbpm-compact-architecture-example-service:8080"
    MANAGEMENT_URL="http://management-console:8280"
    TASK_URL="http://task-console:8380"
    KEYCLOAK_URL="http://keycloak:8480"
	POSTGRES_URL="postgres:5432"
fi

# Function to get Maven variables
get_maven_vars() {
    cd ..
    PROJECT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null || echo "${DEFAULT_VERSION}")
    KOGITO_MANAGEMENT_CONSOLE_IMAGE="docker.io/apache/incubator-kie-kogito-management-console:10.0.0"
    KOGITO_TASK_CONSOLE_IMAGE="docker.io/apache/incubator-kie-kogito-task-console:10.0.0"
    cd - > /dev/null
}

# Check for command line argument
if [ -n "$1" ]; then
    if [[ ("$1" == "full") || ("$1" == "infra") || ("$1" == "example") ]]; then
        PROFILE="$1"
    else
        echo "Unknown docker profile '$1'. The supported profiles are:"
        echo "* 'infra': Use this profile to start only the minimum infrastructure to run the example."
        echo "* 'example': Use this profile to start the example infrastructure and the kogito-example service."
        echo "* 'full' (default): Starts full example setup."
        exit 1;
    fi
fi

# Get Maven variables first
get_maven_vars

# Set registry and browser host
if [ "$USE_CODESPACE" = true ]; then
    REGISTRY_HOST="https://${CODESPACE_NAME}-8080.app.github.dev"
else
    REGISTRY_HOST="http://localhost:8080"
fi

REGISTRY="dev.local"
REGISTRY_PREFIX="${REGISTRY}/${USER}"
IMAGE_TAG="latest"

echo "Using registry prefix: ${REGISTRY_PREFIX}"

# Set registry and browser host
if [ "$(uname)" = "Darwin" ]; then
    BROWSER_HOST="kubernetes.docker.internal"
elif [ "$(expr substr $(uname -s) 1 5)" = "Linux" ]; then
    BROWSER_HOST="172.17.0.1"
fi

# Set registry prefix using system user
REGISTRY="dev.local"
REGISTRY_PREFIX="${REGISTRY}/${USER}"

# Create standardized tag using timestamp
IMAGE_TAG="latest"

echo "Using registry prefix: ${REGISTRY_PREFIX}"
echo "Using image tag: ${IMAGE_TAG}"

# Build the project
cd ..
echo "Building the project with container profile..."
mvn clean install -DskipTests -Pcontainer \
    -Dquarkus.container-image.registry="${REGISTRY}" \
    -Dquarkus.container-image.group="${USER}" \
    -Dquarkus.container-image.name="jbpm-compact-architecture-example-service" \
    -Dquarkus.container-image.tag="${IMAGE_TAG}"

if [ $? -ne 0 ]; then
    echo "Maven build failed"
    exit 1
fi
cd - > /dev/null

# Create .env file
cat << EOF > .env
PROJECT_VERSION=${IMAGE_TAG}
KOGITO_MANAGEMENT_CONSOLE_IMAGE=${KOGITO_MANAGEMENT_CONSOLE_IMAGE}
KOGITO_TASK_CONSOLE_IMAGE=${KOGITO_TASK_CONSOLE_IMAGE}
COMPOSE_PROFILES=${PROFILE}
BROWSER_HOST=${BROWSER_HOST}
REGISTRY_PREFIX=${REGISTRY_PREFIX}
JBPM_URL=${JBPM_URL}
MANAGMENT_URL=${MANAGEMENT_URL}
TASK_URL=${TASK_URL}
KEYCLOAK_URL=${KEYCLOAK_URL}
POSTGRES_URL=${POSTGRES_URL}
USE_CODESPACE=${USE_CODESPACE}

EOF

# Start Docker Compose
echo "Starting Docker Compose with profile: ${PROFILE}"
docker compose up --build

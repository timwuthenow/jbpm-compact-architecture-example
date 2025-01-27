@echo off
setlocal EnableDelayedExpansion

set "PROFILE=full"

:: Check for command line argument
if not "%~1"=="" (
    if "%~1"=="full" (
        set "PROFILE=full"
    ) else if "%~1"=="infra" (
        set "PROFILE=infra"
    ) else if "%~1"=="example" (
        set "PROFILE=example"
    ) else (
        echo Unknown docker profile '%~1'. The supported profiles are:
        echo * 'infra': Use this profile to start only the minimum infrastructure to run the example.
        echo * 'example': Use this profile to start the example infrastructure and the kogito-example service.
        echo * 'full' ^(default^): Starts full example setup.
        exit /b 1
    )
)

:: Check if image exists
docker image inspect dev.local/jbpm-compact-architecture-example-service:1.0.0-SNAPSHOT >nul 2>&1
if %errorlevel% equ 0 (
    :: Image exists, check when it was created
    for /f "tokens=*" %%i in ('docker image inspect -f "{{.Created}}" dev.local/jbpm-compact-architecture-example-service:1.0.0-SNAPSHOT') do set IMAGE_DATE=%%i

    echo Docker image exists, created on: !IMAGE_DATE!
    set /p REBUILD_CHOICE="Do you want to rebuild? (y/N) "

    if /i "!REBUILD_CHOICE!"=="y" (
        goto :build
    ) else (
        goto :setup_env
    )
) else (
    echo Docker image not found, building...
    goto :build
)

:build
:: Get Maven project version and image names
pushd ..
echo Building the project with container profile...
call mvn clean install -DskipTests -Pcontainer

for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=project.version -q -DforceStdout') do set "PROJECT_VERSION=%%i"
for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=kogito.management-console.image -q -DforceStdout') do set "KOGITO_MANAGEMENT_CONSOLE_IMAGE=%%i"
for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=kogito.task-console.image -q -DforceStdout') do set "KOGITO_TASK_CONSOLE_IMAGE=%%i"
popd
goto :setup_env

:setup_env
:: If we didn't build, we still need to get the variables
if not defined PROJECT_VERSION (
    pushd ..
    for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=project.version -q -DforceStdout') do set "PROJECT_VERSION=%%i"
    for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=kogito.management-console.image -q -DforceStdout') do set "KOGITO_MANAGEMENT_CONSOLE_IMAGE=%%i"
    for /f "tokens=*" %%i in ('mvn help:evaluate -Dexpression^=kogito.task-console.image -q -DforceStdout') do set "KOGITO_TASK_CONSOLE_IMAGE=%%i"
    popd
)

:: Create .env file with Windows-specific host setting
(
echo PROJECT_VERSION=%PROJECT_VERSION%
echo KOGITO_MANAGEMENT_CONSOLE_IMAGE=%KOGITO_MANAGEMENT_CONSOLE_IMAGE%
echo KOGITO_TASK_CONSOLE_IMAGE=%KOGITO_TASK_CONSOLE_IMAGE%
echo COMPOSE_PROFILES=%PROFILE%
echo USER=%USERNAME%
echo BROWSER_HOST=localhost
) > .env

:: Check if SVG folder exists
if not exist ".\svg" (
    echo SVG folder does not exist. Have you compiled the project? mvn clean install -DskipTests
    exit /b 1
)

:: Start Docker Compose
docker compose up

# context is the root of the project
# /projects/nopCommerce
# this devcontainer dockerfile in the ./.devcontainer folder

# create the build instance
FROM mcr.microsoft.com/dotnet/sdk:9.0-noble AS build
USER root
RUN dotnet workload update && \
    apt-get update && \
    apt-get install -y \
        sudo \
        openssh-client \
        rsync \
        zsh \
        git \
        curl \
        tree \
        jq \
        postgresql-client \
        mysql-client \
        docker.io \
        containerd && \
    rm -rf /var/lib/apt/lists/* && \
    echo "✓ Development tools installed successfully:" && \
    echo "  - zsh: $(zsh --version)" && \
    echo "  - git: $(git --version)" && \
    echo "  - curl: $(curl --version | head -1)" && \
    echo "  - jq: $(jq --version)" && \
    echo "  - tree: $(tree --version)" && \
    echo "  - psql: $(psql --version)" && \
    echo "  - mysql: $(mysql --version)" && \
    echo "  - docker: $(docker --version)" && \
    echo "  - containerd: $(containerd --version)"
WORKDIR /workspace
# Copy .zshrc for both root and the IDE user
COPY .zshrc /root/.zshrc

# Accept build arguments for username, UID, and GID from docker-compose
ARG IDE_USER
ARG IDE_UID
ARG IDE_GID

# Accept a debug argument for conditional logging during build
ARG DEBUG=false

# Set DEBUG as an environment variable for runtime
ENV DEBUG=${DEBUG}

# in debug mode, show these values
RUN if [ "$DEBUG" = "true" ]; then \
        echo "the passed arg IDE-USER= ${IDE_USER}"; \
        echo "the passed arg IDE-UID= ${IDE_UID}"; \
        echo "the passed arg IDE-GID= ${IDE_GID}"; \
        echo "the passed env DEBUG= ${DEBUG}"; \
    fi



# Remove container image user and group if they conflict with the remoteUser from docker-compose/devcontainer.json
# This is important to avoid conflicts with the user and group IDs
# Step 2: Delete user (if exists)
RUN if grep -q ":${IDE_UID}:" /etc/passwd; then \
      userdel --force -r $(grep ":${IDE_UID}:" /etc/passwd | cut -d: -f1); \
    fi && \
    if [ "$DEBUG" = "true" ]; then \
        echo "User with UID ${IDE_UID} deleted if it existed."; \
    fi && \
    # Delete group if it matches IDE_GID
    if grep -q ":${IDE_GID}:" /etc/group; then \
      groupdel $(grep ":${IDE_GID}:" /etc/group | cut -d: -f1); \
    fi && \
    if [ "$DEBUG" = "true" ]; then \
        echo "Group with GID ${IDE_GID} deleted if it existed."; \
    fi



# Create the docker-compose/devcontainer.json user and add to the sudo group
# only echo out the status if in debug mode
RUN set -eux && \
    if [ "$DEBUG" = "true" ]; then \
        echo "Creating group if it does not exist..."; \
    fi && \
    if ! getent group "${IDE_GID}" >/dev/null; then \
        groupadd --gid "${IDE_GID}" "${IDE_USER}" || (echo "Error: Failed to create group with GID ${IDE_GID}" && exit 1); \
    else \
        if [ "$DEBUG" = "true" ]; then \
            echo "Group with GID ${IDE_GID} already exists."; \
        fi; \
    fi && \
    if [ "$DEBUG" = "true" ]; then \
        echo "Creating user if it does not exist..."; \
    fi && \
    if ! id -u "${IDE_USER}" >/dev/null 2>&1; then \
        useradd --uid "${IDE_UID}" --gid "${IDE_GID}" -m "${IDE_USER}" || (echo "Error: Failed to create user ${IDE_USER} with UID ${IDE_UID} and GID ${IDE_GID}" && exit 1); \
    else \
        if [ "$DEBUG" = "true" ]; then \
            echo "User ${IDE_USER} already exists."; \
        fi; \
    fi && \
    if [ "$DEBUG" = "true" ]; then \
        echo "Adding user to sudoers..."; \
    fi && \
    SUDO_FILE="/etc/sudoers.d/${IDE_USER}" && \
    SUDO_LINE="${IDE_USER} ALL=(ALL) NOPASSWD:ALL" && \
    touch "${SUDO_FILE}" && \
    grep -qF -- "${SUDO_LINE}" "${SUDO_FILE}" || echo "${SUDO_LINE}" >> "${SUDO_FILE}" && \
    chmod 0440 "${SUDO_FILE}" && \
    if [ "$DEBUG" = "true" ]; then \
        echo "Verifying user creation..."; \
    fi && \
    getent passwd "${IDE_USER}" || (echo "Error: User ${IDE_USER} was not created!" && exit 1)

# Copy .zshrc to the IDE user's home directory and install Oh My Zsh
RUN cp /root/.zshrc /home/${IDE_USER}/.zshrc && \
    chown ${IDE_USER}:${IDE_USER} /home/${IDE_USER}/.zshrc && \
    # Install Oh My Zsh for root
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Install Oh My Zsh for IDE_USER
    sudo -u ${IDE_USER} sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Set zsh as default shell for IDE_USER
    chsh -s /usr/bin/zsh ${IDE_USER}


# in debug mode, show the current working directory and its contents
RUN if [ "$DEBUG" = "true" ]; then \
        echo "Current WORKDIR is:"; \
        pwd; \
        echo "Subdirectories under WORKDIR:"; \
        ls -l; \
    fi

# set owner of the workspace directory to the IDE_USER
RUN set -eux && \
    echo "Fixing ownership and permissions for /workspace..." && \
    chown -R ${IDE_USER}:${IDE_USER} /workspace && \
    if [ $? -eq 0 ]; then \
        echo "Ownership successfully changed for /workspace to ${IDE_USER}:${IDE_USER}"; \
    else \
        echo "Failed to change ownership for /workspace"; \
    fi && \
    chmod -R u+rw /workspace

# Setup Clone Script to run from usr/local/bin
COPY ./scripts/clone /usr/local/bin/clone
RUN chmod 755 /usr/local/bin/clone


###############################################################################
#                                                                             #
#      If you want docker to build NopCommerce, uncomment the lines below     #
#                                                                             #
###############################################################################

# Copy the source code and build the application
# # Copy the solution and project files as root
# COPY ./src ./src
# # Ensure ./bin does not exist, because we will create it as $IDE_USER and copy the contents of ./src to ./bin as $IDE_USER
# RUN rm -rf ./bin

# # in debug mode, show the current working directory and its contents
# RUN if [ "$DEBUG" = "true" ]; then \
#         echo "Current WORKDIR is:"; \
#         pwd; \
#         echo "Subdirectories under WORKDIR:"; \
#         ls -l; \
#     fi

# RUN dotnet restore src/NopCommerce.sln --disable-parallel && \
# dotnet clean src/NopCommerce.sln

# # Ensure the IDE_USER has ownership of the workspace directory - dont know if this works. copilot says it cannot be done
# # only echo out the status if in debug mode
# RUN set -eux && \
#     echo "Fixing ownership and permissions for /workspace..." && \
#     chown -R ${IDE_USER}:${IDE_USER} /workspace && \
#     if [ $? -eq 0 ]; then \
#         echo "Ownership successfully changed for /workspace to ${IDE_USER}:${IDE_USER}"; \
#     else \
#         echo "Failed to change ownership for /workspace"; \
#     fi && \
#     chmod -R u+rw /workspace

# # Switch to the non-root user running vscode
# # This is important for security and to avoid permission issues
# # The user should have the same UID and GID as the host user
# # This allows the container to access files on the host without permission issues
# USER ${IDE_USER}
# # Build the solution in Debug mode
# # The --no-incremental option is used to force a full rebuild
# # This is useful when you want to ensure that all projects are built from scratch
# # The -c Debug option specifies the configuration to use (Debug or Release)
# RUN dotnet build /workspace/src/NopCommerce.sln --no-incremental -c Debug


# # Nop gets built into the src folder. So we have to copy this over to the /bin folder
# RUN mkdir ./bin && cp -r ./src/* ./bin/ && \
#     echo "Contents of ./src have been copied to ./bin."

# Set the entrypoint script
#ENTRYPOINT ["./.devcontainer/containers/Nop.Web/entrypoint.sh"]

# Default command to keep the container running after the entrypoint finishes
# this is overriding the entrypoint command from devcontainer.json
# This will only run if you use docker-compose up and not devcontainer up thru vscode
CMD ["tail", "-f", "/dev/null"]

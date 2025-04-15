# context is the root of the project
# /projects/nopCommerce
# this devcontainer dockerfile in the ./.devcontainer folder

# create the build instance 
FROM mcr.microsoft.com/dotnet/sdk:9.0-noble AS build
USER root
# Ensure the .zshrc file exists in the build context before uncommenting the next line
# COPY .zshrc /root/.zshrc
RUN dotnet workload update && \
    apt-get update && \
    apt-get install -y \
    sudo \
    openssh-client \
    rsync && rm -rf /var/lib/apt/lists/* \
    zsh
WORKDIR /workspace
# RUN rm -rf ./bin 
# COPY ./bin/Debug ./bin/Debug

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




# in debug mode, show the current working directory and its contents
RUN if [ "$DEBUG" = "true" ]; then \
    echo "Current WORKDIR is:"; \
    pwd; \
    echo "Subdirectories under WORKDIR:"; \
    ls -l; \
    fi



# # Ensure the IDE_USER has ownership of the workspace directory - dont know if this works. copilot says it cannot be done
# # only echo out the status if in debug mode
# RUN set -eux && \
#     echo "Fixing ownership and permissions for /bin..." && \
#     chown -R ${IDE_USER}:${IDE_USER} /bin && \
#     if [ $? -eq 0 ]; then \
#         echo "Ownership successfully changed for /bin to ${IDE_USER}:${IDE_USER}"; \
#     else \
#         echo "Failed to change ownership for /bin"; \
#     fi && \
#     chmod -R u+rw /bin


# Copy the contents of ./src to ./bin as the non-root user
# This is important to avoid permission issues when removing this folder using the entrypoint script which runs under the IDE_USER
USER ${IDE_USER}

# Explicitly set DOTNET_ROOT and add to PATH for the user
ENV DOTNET_ROOT=/usr/share/dotnet
ENV PATH=${PATH}:${DOTNET_ROOT}

# Verify dotnet installation and environment for the final user
RUN echo "--- Verifying dotnet environment as ${IDE_USER} ---" && \
    echo "User: $(whoami)" && \
    echo "dotnet location: $(command -v dotnet)" && \
    echo "--- dotnet --info ---" && \
    dotnet --info && \
    echo "--- End dotnet --info ---" && \
    echo "DOTNET_ROOT: ${DOTNET_ROOT:-<not set>}" && \
    echo "PATH: ${PATH}" && \
    echo "--- End verification ---"

CMD ["./.devcontainer/containers/Nop.Web/entrypoint.sh"]
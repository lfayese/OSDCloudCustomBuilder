
FROM ubuntu:22.04
# Environment variables and build arguments
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8
ARG NODE_VERSION=20.x
ARG DOTNET_VERSION=8.0
ARG AWSCLI_VERSION=2.15.30
ARG POWERSHELL_VERSION=7.4
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000
# Container metadata
LABEL maintainer="Development Team" \
      description="Development environment with Node.js, .NET, AWS/Azure CLI and Docker tools" \
      version="1.0"
# Consolidate system updates, repository setup, and package installations in one block for caching and performance
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      curl \
      git \
      gnupg \
      locales \
      lsb-release \
      sudo \
      unzip && \
    mkdir -p /etc/apt/keyrings && \
    locale-gen en_US.UTF-8 && \
    \
    # Node.js repository configuration
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_VERSION} jammy main" > /etc/apt/sources.list.d/nodesource.list && \
    \
    # Docker repository configuration
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list && \
    \
    # Microsoft repositories (for .NET SDK and PowerShell)
    curl -fsSL https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb && \
    dpkg -i /tmp/packages-microsoft-prod.deb && \
    rm -f /tmp/packages-microsoft-prod.deb && \
    \
    # Azure CLI repository configuration
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/azurecli.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/azurecli.gpg] https://packages.microsoft.com/repos/azure-cli/ jammy main" > /etc/apt/sources.list.d/azure-cli.list && \
    \
    # Update package lists for new repositories and install development tools with explicit versions
    apt-get update && \
    apt-get install -y --no-install-recommends \
      azure-cli \
      docker-ce-cli \
      docker-compose-plugin \
      dotnet-sdk-${DOTNET_VERSION} \
      nodejs=${NODE_VERSION//x/*} \
      powershell=${POWERSHELL_VERSION}* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    \
    # Install AWS CLI (specific version for reproducibility)
    curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    rm -rf /tmp/awscliv2.zip /tmp/aws && \
    \
    # Configure PowerShell modules
    pwsh -NoLogo -NoProfile -Command \
      "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
       Install-Module OSD -Scope AllUsers -Force -ErrorAction Stop" && \
    \
    # Create non-root user and set workspace permissions
    groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd -s /bin/bash --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} && \
    usermod -aG sudo ${USERNAME} && \
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} && \
    chmod 0440 /etc/sudoers.d/${USERNAME} && \
    mkdir -p /workspace && \
    chown ${USERNAME}:${USERNAME} /workspace

# Create health check script
RUN echo '#!/bin/bash\ncommand -v node && command -v dotnet && command -v aws && command -v az || exit 1' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Basic health check to ensure essential commands exist
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["bash", "/usr/local/bin/healthcheck.sh"]

# Switch to the non-root user and set the working directory
USER ${USERNAME}
WORKDIR /workspace

# Basic health check to ensure essential commands exist
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD ["bash", "/usr/local/bin/healthcheck.sh"]
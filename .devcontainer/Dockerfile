FROM mcr.microsoft.com/powershell:lts-debian-11

# Install additional packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    curl wget unzip git ca-certificates \
    nano less htop procps \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Create a non-root user
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Create directories for OSDCloud caching
RUN mkdir -p /home/vscode/OSDCloud/OS /home/vscode/OSDCloud/Drivers /home/vscode/OSDCloud/Autopilot \
    && chown -R $USERNAME:$USERNAME /home/vscode/OSDCloud

USER $USERNAME

# Install PowerShell modules one by one to isolate failures
RUN pwsh -Command 'Set-PSRepository -Name PSGallery -InstallationPolicy Trusted'
RUN pwsh -Command 'Install-Module -Name OSD -Force -AllowClobber -Verbose'
RUN pwsh -Command 'Install-Module -Name PSWindowsUpdate -Force -AllowClobber -Verbose'
RUN pwsh -Command 'Install-Module -Name WindowsAutoPilot -Force -AllowClobber -Verbose'
RUN pwsh -Command 'Install-Module -Name Microsoft.Graph -Force -AllowClobber -Verbose'
RUN pwsh -Command 'Install-Module -Name WindowsAutopilotIntune -Force -AllowClobber -Verbose' 
RUN pwsh -Command 'Install-Module -Name Pester -Force -SkipPublisherCheck -Verbose'
RUN pwsh -Command 'Install-Module -Name PSScriptAnalyzer -Force -AllowClobber -Verbose'

# Set up PowerShell profile
RUN mkdir -p /home/vscode/.config/powershell \
    && echo 'Import-Module PSScriptAnalyzer' > /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Import-Module Pester' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Set-PesterPreference -Output Detailed' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1 \
    && echo 'Write-Host "OSDCloud Custom Builder Development Environment Ready" -ForegroundColor Green' >> /home/vscode/.config/powershell/Microsoft.PowerShell_profile.ps1
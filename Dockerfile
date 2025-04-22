# Use an official Ubuntu image as the base
FROM ubuntu:latest

RUN userdel -r ubuntu || true

# Set DEBIAN_FRONTEND to noninteractive to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Define arguments for user configuration (can be overridden at build time)
ARG USERNAME=auditor
ARG USER_UID=1000
ARG USER_GID=1000
ARG USER_HOME=/home/$USERNAME

# Update package lists and install essential tools, zsh, git, sudo, and CA certificates
# ca-certificates is needed for secure HTTPS connections
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    vim \
    neovim \
    git \
    zip \
    unzip \
    zsh \
    procps \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add /bin/zsh to /etc/shells if it's not already there
RUN echo "/bin/zsh" | tee -a /etc/shells

# Create the non-root user with zsh as the default shell
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID --shell /bin/zsh --create-home --home-dir $USER_HOME $USERNAME

# Switch to the non-root user
USER $USERNAME

# Set the working directory to the user's home directory
WORKDIR $USER_HOME

# Clone Oh-My-Zsh repository directly
RUN git clone https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh

# Create a .zshrc file that sources Oh-My-Zsh
RUN cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

# Set the default command to run zsh
CMD ["zsh"]
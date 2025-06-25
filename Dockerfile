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

# Install Node.js 20 repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash -

# Update package lists and install essential tools, zsh, git, sudo, and CA certificates
# ca-certificates is needed for secure HTTPS connections
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
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
    sudo \
    fzf \
    man-db \
    gnupg2 \
    gh \
    iptables \
    ipset \
    iproute2 \
    dnsutils \
    aggregate \
    jq \
    less \
    && rm -rf /var/lib/apt/lists/*

# Add /bin/zsh to /etc/shells if it's not already there
RUN echo "/bin/zsh" | tee -a /etc/shells

# Create the non-root user with zsh as the default shell
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID --shell /bin/zsh --create-home --home-dir $USER_HOME $USERNAME

# Set up npm global directory and permissions
RUN mkdir -p /usr/local/share/npm-global && \
    chown -R $USERNAME:$USERNAME /usr/local/share

# Create workspace and config directories
RUN mkdir -p /workspace $USER_HOME/.claude /commandhistory && \
    touch /commandhistory/.bash_history && \
    chown -R $USERNAME:$USERNAME /workspace $USER_HOME/.claude /commandhistory

ENV DEVCONTAINER=true

# Set up sudo access for the user
RUN echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Set environment variables
ENV DEVCONTAINER=true
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/zsh

# Switch to the non-root user
USER $USERNAME

# Set the working directory to the user's home directory
WORKDIR $USER_HOME

# Set up Oh-My-Zsh with additional configuration
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Copy and set up firewall script (if you have one)
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/$USERNAME-firewall && \
    chmod 0440 /etc/sudoers.d/$USERNAME-firewall
USER $USERNAME

# Set the working directory to workspace for development
WORKDIR /workspace

# Set the default command to run zsh
CMD ["zsh"]

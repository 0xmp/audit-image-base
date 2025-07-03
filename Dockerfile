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

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace $USER_HOME/.claude /commandhistory && \
    touch /commandhistory/.bash_history && \
    chown -R $USERNAME:$USERNAME /workspace $USER_HOME/.claude /commandhistory


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

# Set the working directory to workspace for development
WORKDIR /workspace

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.0/zsh-in-docker.sh)" -- \
    -p git \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x && \
    # Find and configure fzf paths manually
    FZF_KEY_BINDINGS=$(find /usr -name "key-bindings.zsh" 2>/dev/null | head -1) && \
    FZF_COMPLETION=$(find /usr -name "completion.zsh" 2>/dev/null | grep fzf | head -1) && \
    if [ -n "$FZF_KEY_BINDINGS" ] && [ -f "$FZF_KEY_BINDINGS" ]; then \
        echo "[ -f \"$FZF_KEY_BINDINGS\" ] && source \"$FZF_KEY_BINDINGS\"" >> ~/.zshrc; \
    fi && \
    if [ -n "$FZF_COMPLETION" ] && [ -f "$FZF_COMPLETION" ]; then \
        echo "[ -f \"$FZF_COMPLETION\" ] && source \"$FZF_COMPLETION\"" >> ~/.zshrc; \
    fi

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Copy and set up firewall script (if you have one)
COPY init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/$USERNAME-firewall && \
    chmod 0440 /etc/sudoers.d/$USERNAME-firewall
USER $USERNAME

# Set the default command to run zsh
CMD ["zsh"]

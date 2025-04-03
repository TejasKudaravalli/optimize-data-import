# Use Debian as the base image
FROM debian:latest

# Install required tools
RUN apt-get update && apt-get install -y \
    curl \
    zstd \
    jq \
    postgresql-client \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /sql

# Default entrypoint
ENTRYPOINT ["/bin/bash"]

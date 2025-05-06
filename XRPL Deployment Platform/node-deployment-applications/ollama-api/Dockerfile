# Use Ubuntu 24 as the base image
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    build-essential \
    python3 \
    python3-pip \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20.x and latest npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Set working directory
WORKDIR /usr/src/ollama-api

# Copy the zip into container
COPY Ollama.zip /tmp/ollama.zip

# Extract and move content into the working directory
RUN unzip /tmp/ollama.zip -d /usr/src/ollama-api-tmp && \
    mv /usr/src/ollama-api-tmp/Ollama/* /usr/src/ollama-api && \
    rm -rf /usr/src/ollama-api-tmp /tmp/ollama.zip

# Install app dependencies
RUN npm install --omit=dev

# Expose the API port
EXPOSE 3011

# Start the application
CMD ["node", "app.js"]

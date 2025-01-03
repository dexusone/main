#!/bin/bash

echo "Docker Fixer Script - Starting..."

# Stop Docker service
echo "Stopping Docker service..."
sudo systemctl stop docker

# Uninstall Docker completely
echo "Uninstalling Docker and cleaning up..."
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd ~/.docker
sudo apt-get autoremove -y && sudo apt-get autoclean -y

# Reinstall Docker
echo "Reinstalling Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
echo "Verifying Docker installation..."
if docker --version; then
    echo "Docker installed successfully!"
else
    echo "Docker installation failed. Please check manually."
    exit 1
fi

# Set up DNS configuration
echo "Configuring Docker DNS..."
echo '{"dns":["8.8.8.8","8.8.4.4"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Test Docker
echo "Testing Docker with hello-world..."
if docker run --rm hello-world; then
    echo "Docker is working correctly!"
else
    echo "Docker test failed. Please check manually."
    exit 1
fi

# Clean up Docker networks
echo "Cleaning up Docker networks..."
docker network prune -f

echo "Docker Fixer Script - Complete!"

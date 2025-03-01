#!/bin/bash

set -e  # Exit script on any command failure
set -o pipefail  # Catch errors in piped commands

echo "🚀 Fixing Docker login and credential storage issues..."

# Step 1: Ensure necessary dependencies are installed
echo "🔄 Updating package lists and installing required dependencies..."
sudo apt update && sudo apt install -y pass gnupg2

# Step 2: Check if a GPG key exists
GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "rsa" | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

if [ -z "$GPG_KEY_ID" ]; then
    echo "🔑 No GPG key found."
    echo "Please enter your email for the GPG key (e.g., your-email@example.com):"
    read -r GPG_EMAIL

    gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 3072
Name-Real: docker-user
Name-Email: $GPG_EMAIL
Expire-Date: 0
%no-protection
%commit
EOF

    # Fetch newly created GPG key ID
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep "rsa" | awk '{print $2}' | cut -d'/' -f2 | head -n 1)

    if [ -z "$GPG_KEY_ID" ]; then
        echo "❌ GPG key generation failed. Exiting."
        exit 1
    fi
fi

echo "✅ GPG key found: $GPG_KEY_ID"

# Step 3: Initialize 'pass' with the GPG key (if not already initialized)
if ! pass show test &>/dev/null; then
    echo "🛠 Initializing 'pass' with the GPG key..."
    pass init "$GPG_KEY_ID"
else
    echo "✅ 'pass' is already initialized."
fi

# Step 4: Ensure password store directory exists
mkdir -p ~/.password-store

# Step 5: Test if 'pass' is working
echo "🔎 Verifying 'pass' functionality..."
echo "test-password" | pass insert -f test

if [ $? -eq 0 ]; then
    echo "✅ 'pass' is working correctly."
else
    echo "❌ 'pass' failed. Falling back to plaintext credential storage."
    mkdir -p ~/.docker
    echo '{ "credsStore": "desktop" }' > ~/.docker/config.json
fi

# Step 6: Ensure Docker CLI is installed
if ! command -v docker &>/dev/null; then
    echo "❌ Docker CLI is not installed. Please install it and rerun the script."
    exit 1
fi

# Step 7: Logout and retry Docker login
echo "🔄 Logging out of Docker to reset authentication..."
docker logout

echo "🔐 Attempting to log in to Docker..."
if ! docker login; then
    echo "❌ Docker login failed. Try manually logging in with:"
    echo "   docker login -u <your-username>"
    exit 1
fi

echo "✅ Docker login successful!"

# Step 8: Push Docker image if login is successful
DOCKER_IMAGE="dexusone/k8s-web-hello-ru-2:latest"
echo "🚀 Pushing Docker image: $DOCKER_IMAGE"
if ! docker push "$DOCKER_IMAGE"; then
    echo "❌ Failed to push Docker image. Check permissions and try again."
    exit 1
fi

echo "✅ All steps completed successfully!"

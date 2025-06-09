# Zarf Hello World Example

This repository contains a simple "Hello World" application packaged with Zarf.

## Prerequisites

### System Requirements

- Linux or macOS
- Docker
- Zarf CLI
- Kind (Kubernetes in Docker)

### Installation Instructions

#### Linux

```bash
# Install Docker-CE
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker $USER
# Log out and log back in so that your group membership is re-evaluated.

# Enable on boot with systemd
sudo systemctl enable docker.service --now
sudo systemctl enable containerd.service --now
```

```bash
# Install Helm
## From Apt (Debian/Ubuntu)

curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

```bash
# Install Zarf
ZARF_VERSION=$(curl -sIX HEAD https://github.com/zarf-dev/zarf/releases/latest | grep -i ^location: | grep -Eo 'v[0-9]+.[0-9]+.[0-9]+')

curl -sL "https://github.com/zarf-dev/zarf/releases/download/${ZARF_VERSION}/zarf_${ZARF_VERSION}_Linux_amd64" -o zarf
chmod +x zarf
sudo mv zarf /usr/local/bin/zarf
```

```bash
# Install Kind
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

#### macOS

```bash
# Install Zarf
wget https://github.com/defenseunicorns/zarf/releases/download/v0.54.0/zarf_0.54.0_darwin_amd64.tar.gz
mkdir -p /usr/local/bin
sudo tar -xzf zarf_0.54.0_darwin_amd64.tar.gz -C /usr/local/bin
rm zarf_0.54.0_darwin_amd64.tar.gz

# Install Kind
wget https://kind.sigs.k8s.io/dl/v0.22.0/kind-darwin-amd64
chmod +x kind-darwin-amd64
sudo mv kind-darwin-amd64 /usr/local/bin/kind

# Alternatively, you can use Homebrew on macOS
brew install kind
brew install zarf
```

### Verification

After installation, verify that both tools are working:

```bash
# Check Zarf version
zarf version

# Check Kind version
kind version

# Check Docker version
docker --version
```

## Building the Application

1. Build and push the Docker image using buildx:

```bash
docker buildx build --push --platform linux/amd64,linux/arm64 -t docker.io/johnemiller607/zarf-hello-world:latest .
```
## Kubernetes Manifest Details

### Deployment Configuration
The deployment.yaml file configures:
- 2 replicas for high availability
- Resource limits:
  - Memory: 128Mi
  - CPU: 200m
- Resource requests:
  - Memory: 64Mi
  - CPU: 100m
- Health checks:
  - Liveness probe: Checks every 10 seconds after 30 second delay
  - Readiness probe: Checks every 10 seconds after 5 second delay

### Service Configuration
The service.yaml file configures:
- NodePort service type for external access
- Port mapping:
  - External port: 80
  - Target container port: 8080
- Automatic load balancing across replicas

### Kustomization
The kustomization.yaml file manages:
- Resource references
- Name prefix for all resources
- Container image configuration

## Creating Zarf Package

Create a zarf.yaml file:
```yaml
apiVersion: zarf.dev/v1alpha1
kind: ZarfPackageConfig
metadata:
  name: hello-world
spec:
  version: 0.0.1

components:
  - name: hello-world-app
    required: true
    manifests:
    - name: hello-world-deployment
      namespace: hello-world
      kustomizations:
      - https://github.com/millerjem/zarf-hello-world/kustomize?ref=main
    images:
      - docker.io/johnemiller607/zarf-hello-world:latest
```

## Deploying with Zarf

1. Initialize Zarf:
```bash
zarf init
```

2. Package your application:
```bash
zarf package create . -a amd64
zarf package create . -a arm64
```

3. Deploy the package:
```bash
zarf package deploy .
```

### Deployment Configuration
The deployment.yaml file configures:
- 2 replicas for high availability
- Resource limits:
  - Memory: 128Mi
  - CPU: 200m
- Resource requests:
  - Memory: 64Mi
  - CPU: 100m
- Health checks:
  - Liveness probe: Checks every 10 seconds after 30 second delay
  - Readiness probe: Checks every 10 seconds after 5 second delay

### Service Configuration
The service.yaml file configures:
- NodePort service type for external access
- Port mapping:
  - External port: 80
  - Target container port: 8080
- Automatic load balancing across replicas

### Kustomization
The kustomization.yaml file manages:
- Resource references
- Name prefix for all resources
- Container image configuration

## Accessing the Application

Once deployed, you can access the application by:
1. Finding the NodePort service:
```bash
kubectl get svc
```

2. Accessing the application at:
```
http://<node-ip>:<node-port>
```

## Cleaning Up

To remove the application:
```bash
zarf package remove hello-world
```

## Notes

- This example uses a simple Flask application running on port 8080
- The application is exposed via a NodePort service in Kubernetes
- You can modify the application code in `app.py` to customize the behavior
- Ensure your Kubernetes cluster has sufficient resources to run the application

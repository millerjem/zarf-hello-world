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
# Install Zarf
wget https://github.com/defenseunicorns/zarf/releases/download/v0.54.0/zarf_0.54.0_linux_amd64.tar.gz
mkdir -p /usr/local/bin
sudo tar -xzf zarf_0.54.0_linux_amd64.tar.gz -C /usr/local/bin
rm zarf_0.54.0_linux_amd64.tar.gz

# Install Kind
wget https://kind.sigs.k8s.io/dl/v0.22.0/kind-linux-amd64
chmod +x kind-linux-amd64
sudo mv kind-linux-amd64 /usr/local/bin/kind
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

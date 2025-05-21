# Zarf Hello World Example

This repository contains a simple "Hello World" application packaged with Zarf.

## Prerequisites

- Zarf CLI installed on your system
- A Kubernetes cluster
- Docker installed (for building the container)

## Building the Application

1. Build and push the Docker image using buildx:
```bash
docker buildx build --push --platform linux/amd64 -t docker.io/johnemiller607/zarf-hello-world:latest .
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
kind: ZarfPackage
metadata:
  name: hello-world
spec:
  components:
    - name: hello-world-app
      files:
        - path: zarf-hello-world:latest
          containerImage: true
          containerImageTag: latest
      dependencies:
        - kubernetes
      kustomize:
        path: kustomize
        resources:
          - deployment.yaml
          - service.yaml
```

## Deploying with Zarf

1. Initialize Zarf:
```bash
zarf init
```

2. Package your application:
```bash
zarf package create ./zarf.yaml
```

3. Deploy the package:
```bash
zarf package deploy ./zarf-hello-world.zarf.yaml
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

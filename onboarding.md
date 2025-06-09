# Mission Lab Deployment Guide: Zarf Packages, UDS Bundles, Pepr Exceptions, and Company-Specific Registry Access

## Overview
Mission Lab is a Kubernetes-based environment designed to support cloud, on-premises, and disconnected (air-gapped) deployments for mission-critical applications. It provides services such as multi-tenant storage via MinIO and ML/DL/AI capabilities through Tenjin and Koverse. The only supported method for deploying applications into Mission Lab is through Zarf packages and UDS bundles, which ensure secure, declarative, and portable software delivery. This document details the process of creating, building, validating, testing, and deploying mission-critical applications in Mission Lab, including requesting Pepr exceptions to bypass cluster policies, accessing company-specific registries for package and bundle storage, and utilizing GitLab CI/CD pipelines for automation.

## Prerequisites
- **Kubernetes Cluster**: A running Kubernetes cluster (e.g., k3s, k3d, or other distributions) compatible with Mission Lab.
- **Zarf CLI**: Installed on both development and target machines. Installation instructions are available at [Zarf Documentation](https://docs.zarf.dev/). For Mac/Linux with Homebrew: `brew install zarf`.
- **UDS CLI**: Installed for bundling and deploying UDS bundles. For Mac/Linux with Homebrew: `brew install defenseunicorns/tap/uds`.
- **Git Repository**: A repository (e.g., similar to `zarf-hello-world`) containing application configurations.
- **Access to Mission Lab**: Ensure access to the Mission Lab environment (cloud, on-premises, or disconnected).
- **Company-Specific Registry**: Access to an OCI-compliant registry (e.g., Harbor, Artifactory, or a private Docker registry) for storing Zarf packages and UDS bundles.
- **Registry Credentials**: Valid credentials (username, password, or token) for the company-specific registry.
- **Pepr Knowledge**: Familiarity with Pepr policies in Mission Lab, which enforce security and compliance (e.g., namespace restrictions, pod security standards).
- **GitLab CI/CD Access**: Access to the company’s GitLab instance for CI/CD pipelines, including credentials for pushing/pulling Zarf packages and UDS bundles to/from the repository.

## Process for Deploying Mission-Critical Applications

### 1. Creating Zarf Packages
Zarf packages encapsulate all necessary components, including Docker images, Helm charts, and Kubernetes manifests, into a single tarball for deployment, especially in air-gapped environments.

- **Define the Zarf Package Configuration**:
  Create a `zarf.yaml` file to define the package. For example, a `podinfo` application configuration:
  ```yaml
  kind: ZarfPackageConfig
  metadata:
    name: podinfo
    version: "0.0.1"
  components:
    - name: podinfo
      required: true
      charts:
        - name: podinfo
          url: https://stefanprodan.github.io/podinfo
          version: 6.4.0
      images:
        - stefanprodan/podinfo:6.4.0
  ```
- **Include Mission Lab Services**:
  Ensure integration with Mission Lab services (e.g., MinIO, Tenjin/Koverse). For example, configure MinIO access:
  ```yaml
  // Placeholder
  ```
### 2. Building Zarf Packages
- **Create the Package**:
  In the directory containing `zarf.yaml`, run:
  ```bash
  zarf package create --architecture <amd64 | arm64>
  ```
  This generates a tarball (e.g., `zarf-package-podinfo-<architecture>-0.0.1.tar.zst`).
- **Handle Air-Gapped Environments**:
  Include all images and resources:
  ```bash
  zarf package create --sbom
  ```
  This generates a Software Bill of Materials (SBOM) for compliance.
- **Sign the Package**:
  Use Cosign for package integrity:
  ```bash
  zarf package create --sign
  ```

### 3. Creating UDS Bundles
UDS bundles combine multiple Zarf packages into a single deployable artifact.

- **Define the UDS Bundle Configuration**:
  Create a `uds-bundle.yaml` file:
  ```yaml
  kind: UDSBundle
  metadata:
    name: mission-lab-bundle
    version: "0.0.1"
  packages:
    - name: init
      repository: ghcr.io/defenseunicorns/zarf/init
      ref: v0.30.0
    - name: core
      repository: ghcr.io/defenseunicorns/uds-core
      ref: v0.1.0
    - name: podinfo
      path: ./zarf-package-podinfo-<architecture>-0.0.1.tar.zst
  ```
- **Include Mission Lab Services**:
  Add packages for MinIO, Tenjin, or Koverse:
  ```yaml
  packages:
    - name: minio
      repository: ghcr.io/defenseunicorns/uds-package-minio
      ref: v4.4.28
  ```
- **Create the Bundle**:
  Run:
  ```bash
  uds create --architecture <amd64 | arm64>
  ```
  This generates a tarball (e.g., `uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst`).

### 4. Accessing Company-Specific Registries
Mission Lab deployments often require pulling Zarf packages or UDS bundles from a company-specific OCI-compliant registry (e.g., Harbor, Artifactory). This is critical for connected environments and may require additional configuration for air-gapped setups.

- **Configure Registry Access**:
  1. **Obtain Credentials**: Secure credentials (username, password, or token) from the company registry administrator.
  2. **Authenticate with Zarf**:
     Configure Zarf to access the registry:
     ```bash
     zarf tools registry login <registry-url> -u <username> -p <password>
     ```
     Example: `zarf tools registry login harbor.company.com -u dev-user -p my-secret-password`.
  3. **Authenticate with UDS**:
     Configure UDS CLI similarly:
     ```bash
     uds registry login <registry-url> -u <username> -p <password>
     ```
- **Push Packages to Registry**:
  After building the Zarf package, push it to the company registry:
  ```bash
  zarf package publish zarf-package-podinfo-<architecture>-0.0.1.tar.zst oci://<registry-url>/mission-lab/podinfo:0.0.1
  ```
  For UDS bundles:
  ```bash
  uds publish uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst oci://<registry-url>/mission-lab:0.0.1
  ```
- **Pull Packages from Registry**:
  In connected environments, pull packages during deployment:
  ```bash
  zarf package deploy oci://<registry-url>/mission-lab/podinfo:0.0.1
  ```
  or
  ```bash
  uds deploy oci://<registry-url>/mission-lab:0.0.1 --confirm
  ```
- **Air-Gapped Registry Access**:
  For disconnected environments:
  1. Export packages/bundles from the registry in a connected environment:
     ```bash
     zarf package pull oci://<registry-url>/mission-lab/podinfo:0.0.1
     ```
     or
     ```bash
     uds pull oci://<registry-url>/mission-lab:0.0.1
     ```
  2. Transfer the resulting tarballs to the air-gapped environment via physical media (e.g., USB drive).
  3. Deploy as described in the deployment section.

### 5. Using Mission Lab GitLab CI/CD Pipelines for Building and Validating
Mission Lab leverages GitLab CI/CD pipelines to automate the validation, building, integration, cleanup, and publishing of Zarf packages and UDS bundles. The pipeline ensures compliance with security standards and facilitates deployment to the company-specific registry.

- **Accessing the GitLab Repository**:
  1. **Obtain Repository Access**:
     Secure access to the GitLab repository (e.g., `https://gitlab.sif.saicdevops.com/saic-labs/mission-lab`) through the GitLab administrator.
     Ensure your GitLab account has appropriate permissions (e.g., Developer or Maintainer) to push code and trigger pipelines.
  2. **Clone the Repository**:
     Clone the repository to your local machine:
     ```bash
     git clone https://gitlab.sif.saicdevops.com/saic-labs/mission-lab/<repository-name>.git
     ```
  3. **Configure GitLab Runner**:
     Ensure a GitLab Runner is configured for the repository with the necessary tools (Zarf CLI, UDS CLI, Lula, Cosign, container scanning tools).
  4. **Push Changes to Trigger Pipeline**:
     Commit and push changes to the repository to initiate the pipeline:
     ```bash
     git add .
     git commit -m "Update zarf.yaml and uds-bundle.yaml"
     git push origin main
     ```
  5. **Accessing Pipeline Artifacts**:
     Options 1:
     - After the pipeline completes, access Zarf packages and UDS bundles in the GitLab Artifacts, Packages, or Registry section of the pipeline job.
     - Pull packages/bundles or download tarballs for deployment or transfer to air-gapped environments via physical media (e.g., USB drive).
  7. **Transferring to Air-Gapped Environments**:
     - Transfer the tarballs, along with Zarf CLI, UDS CLI, and `zarf init` package, to the air-gapped machine using secure physical media.
     - Follow the air-gapped deployment steps in the deployment section.

- **GitLab CI/CD Pipeline Structure**:
  The pipeline consists of five sections, each with specific tasks to ensure compliance and successful deployment. To publish a Zarf package or UDS bundle, the package must pass Pepr policies and container scanning with no critical or high-severity CVEs.

  ```mermaid
  graph TD
      A[Validation] --> B[Build]
      B --> C[Integration]
      C --> D[Cleanup]
      C --> E[Publish]
      A --> |Pre-commits| F[Code Quality Checks]
      A --> |OSCAL Scanning/Reports| G[Lula Compliance Reports]
      B --> |Build Package| H[Zarf/UDS Package Creation]
      B --> |SBOM Generation| I[SBOM Creation]
      C --> |Container Scanning| J[Scan for CVEs]
      C --> |Deploy| K[Deploy to Test Cluster]
      C --> |Tests| L[Functional Tests]
      C --> |Pepr Scans| M[Pepr Policy Checks]
      D --> |Cleanup| N[Remove Test Resources]
      E --> |Publish| O[Push to Registry]
  ```

  - **Validation**:
    - **Pre-commits**: Runs code quality checks (e.g., linting, formatting) using tools like pre-commit hooks to ensure code consistency.
    - **OSCAL Scanning/Reports**: Uses Lula to generate NIST OSCAL compliance reports for auditing.
  - **Build**:
    - **Build Package**: Executes `zarf package create` or `uds create` to generate tarballs.
    - **SBOM Generation**: Runs `zarf package create --sbom` to create a Software Bill of Materials for compliance.
  - **Integration**:
    - **Container Scanning**: Scans container images for vulnerabilities using tools like Trivy, ensuring no critical or high-severity CVEs.
    - **Deploy**: Deploys the package/bundle to a test Kubernetes cluster using `zarf package deploy` or `uds deploy`.
    - **Tests**: Runs functional tests to verify application behavior.
    - **Pepr Scans**: Checks for Pepr policy violations using `uds deploy` and reviews logs in the `pepr-system` namespace.
  - **Cleanup**:
    - **Cleanup**: Removes test resources from the cluster to maintain a clean environment.
  - **Publish**:
    - **Publish**: Pushes the package/bundle to the company-specific registry using `zarf package publish` or `uds publish` if all checks pass (Pepr policies and container scanning).

### 6. Validating Packages and Bundles
- **Validate Zarf Package**:
  Inspect package contents:
  ```bash
  zarf package inspect zarf-package-podinfo-<architecture>-0.0.1.tar.zst
  ```
- **Validate UDS Bundle**:
  List images and components:
  ```bash
  uds inspect uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst --list-images
  ```
- **Check Compliance**:
  Use Lula for NIST OSCAL compliance:
  ```bash
  lula validate -f oscal-component-opa.yaml
  ```
  Use Lula to evalute the results in assessment-results.yaml:
  ```bash
  lula evaluate lula evaluate -f assessment-results.yaml
  ```
- **Verify MinIO Integration**:
  ```
  // Placeholder
  ```
- **Verify Registry Access**:
  Confirm that packages/bundles can be pulled from the company registry:
  ```bash
  zarf package pull oci://<registry-url>/mission-lab/podinfo:0.0.1
  ```
- **Verify CI/CD Pipeline**:
  Check GitLab pipeline status to ensure all stages (validation, build, integration, cleanup, publish) complete successfully. Review logs and artifacts for any issues.

### 7. Requesting a Pepr Exception
Mission Lab uses Pepr to enforce security and compliance policies. If a package or bundle violates these policies, a Pepr exception is required.

- **Identify Policy Violations**:
  Attempt deployment:
  ```bash
  uds deploy uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst --confirm
  ```
  Review Pepr logs for violations: `kubectl logs -n pepr-system <pepr-pod>`.
  Check GitLab pipeline logs for Pepr scan failures in the integration stage.
- **Submit a Pepr Exception Request**:
  
  1. **Naviagte to the Repository Root**
     ```
     cd <repository-name>
     ```
  2. **Create the Pepr Exception Document**:
     ```markdown
     # Pepr Exception Request
     **Package/Bundle**: mission-lab-bundle-0.0.1
     **Policy Violated**: PodSecurityPolicy - Privileged Containers
     **Justification**: Requires privileged access for GPU-based AI processing via Tenjin.
     **Mitigations**: Deploy in isolated namespace (`mission-lab-gpu`) with restricted RBAC.
     **Duration**: 6 months
     ```
     ```yaml
     apiVersion: pepr.dev/v1alpha1
     kind: PeprException
     metadata:
       name: example-exception
       namespace: pepr-system  # Adjust namespace if different
     spec:
       exceptions:
       - namespace: "<namespace>"  # Example: Exempt an entire namespace
         resourceKind: "*"  # Exempt all resource kinds in this namespace
       - namespace: "default"
         resourceKind: "Pod"      # Exempt specific resource type
         resourceName: "hello-world-*"  # Exempt resources matching this pattern
         policy: enforce-pod-labels  # Specific policy to exempt
     ```     
  3. **Submit to Admins**: Send to Mission Lab administrators via designated channels (e.g., GitLab issue or email).
  4. **Include Artifacts**: Attach SBOM and Lula validation results from the GitLab pipeline artifacts.
  5. **Specify Duration**: Request temporary or permanent exception.
- **Verify the Exception**:
  Admins update the Pepr configuration (e.g., ConfigMap in `pepr-system` namespace):
  ```yaml
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: pepr-exemption
    namespace: pepr-system
  data:
    exemptions: |
      - namespace: mission-lab
        pod: podinfo
        policy: no-privileged-containers
  ```
- **Deploy with the Exception**:
  Redeploy via the GitLab pipeline or manually:
  ```bash
  uds deploy uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst --confirm
  ```
  Confirm success in pipeline logs or deployment status.

### 8. Testing
- **Local Testing**:
  Deploy to a local cluster:
  ```bash
  zarf init
  zarf package deploy zarf-package-podinfo-<architecture>-0.0.1.tar.zst
  ```
  or
  ```bash
  uds deploy uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst
  ```
- **Test Mission Lab Services**:
  - **MinIO**: Verify object storage functionality.
  - **Tenjin/Koverse**: Test ML/DL/AI workflows.
- **Functional Testing**:
  Check pod status:
  ```bash
  kubectl get all -n mission-lab
  ```
  Review test results from the GitLab pipeline integration stage.
- **Pepr Exception Testing**:
  Verify that previously blocked components deploy successfully in the pipeline or manual deployment.
- **Registry Access Testing**:
  Test pulling packages/bundles from the company registry in a connected environment.
- **Air-Gapped Testing**:
  Simulate a disconnected environment using tarballs from GitLab Artifacts to verify functionality.

### 9. Deploying to Mission Lab
- **Connected Environment**:
  Deploy from the company registry:
  ```bash
  uds deploy oci://<registry-url>/mission-lab:0.0.1 --confirm
  ```
- **Disconnected Environment**:
  1. Download tarballs from GitLab Artifacts or pull from the registry in a connected environment:
     ```bash
     zarf package pull oci://<registry-url>/mission-lab/podinfo:0.0.1
     ```
     or
     ```bash
     uds pull oci://<registry-url>/mission-lab:0.0.1
     ```
  2. Transfer Zarf CLI, UDS CLI, `zarf init` package, and tarballs to the air-gapped machine.
  3. Initialize the cluster:
     ```bash
     zarf init
     ```
  4. Deploy the bundle:
     ```bash
     uds deploy uds-bundle-mission-lab-bundle-<architecture>-0.0.1.tar.zst --confirm
     ```
- **Verify Deployment**:
  Check resources:
  ```bash
  kubectl get all -n mission-lab
  ```
  Confirm MinIO, Tenjin, and Koverse functionality.

## Deployment Checklist
```markdown
# Mission Lab Deployment Checklist

## Prerequisites
- [ ] Install Zarf CLI (`brew install zarf`)
- [ ] Install UDS CLI (`brew install defenseunicorns/tap/uds`)
- [ ] Install UDS CLI (`brew install defenseunicorns/tap/lula`)
- [ ] Set up a Kubernetes cluster (e.g., k0s, kind, k3s, k3d)
- [ ] Verify access to Mission Lab environment
- [ ] Configure MinIO for multi-tenant storage
- [ ] Ensure Tenjin and Koverse are available for ML/DL/AI (if needed)
- [ ] Initialize Git repository for application configurations
- [ ] Review Pepr policies enforced in Mission Lab
- [ ] Obtain credentials for company-specific registry
- [ ] Verify access to company registry (e.g., Harbor, Artifactory)
- [ ] Obtain access to GitLab repository (`https://gitlab.company.com/mission-lab`)
- [ ] Configure GitLab Runner for CI/CD pipeline

## Creating Zarf Packages
- [ ] Create `zarf.yaml` with application components (e.g., podinfo)
- [ ] Include MinIO secrets for storage integration
- [ ] Add Tenjin/Koverse configurations for AI capabilities (if applicable)
- [ ] Include UDS Package Custom Resource for UDS Core compatibility
- [ ] Add registry credentials secret for air-gapped deployments

## Building Zarf Packages
- [ ] Run `zarf package create` to generate package tarball
- [ ] Generate SBOM for compliance (`zarf package create --sbom`)
- [ ] Sign package with Cosign (`zarf package create --sign`)

## Creating UDS Bundles
- [ ] Create `uds-bundle.yaml` specifying Zarf packages
- [ ] Include `init`, `core`, and application packages
- [ ] Add MinIO, Tenjin, or Koverse packages as needed
- [ ] Run `uds create` to generate bundle tarball

## Using GitLab CI/CD Pipelines
- [ ] Clone GitLab repository (`git clone https://gitlab.company.com/mission-lab/<repository-name>.git`)
- [ ] Commit and push `zarf.yaml` and `uds-bundle.yaml` to trigger pipeline
- [ ] Monitor pipeline stages (Validation, Build, Integration, Cleanup, Publish)
- [ ] Verify no critical or high-severity CVEs in container scanning
- [ ] Verify Pepr policy compliance in integration stage
- [ ] Download tarballs from GitLab Artifacts for deployment
- [ ] For air-gapped environments, transfer tarballs via physical media

## Accessing Company-Specific Registry
- [ ] Authenticate Zarf CLI with registry (`zarf tools registry login`)
- [ ] Authenticate UDS CLI with registry (`uds registry login`)
- [ ] Push Zarf package to registry (`zarf package publish`)
- [ ] Push UDS bundle to registry (`uds publish`)
- [ ] For air-gapped environments:
  - [ ] Pull packages/bundles from registry in connected environment
  - [ ] Transfer tarballs to air-gapped machine
- [ ] Verify registry pull in connected environment (`zarf package pull` or `uds pull`)

## Validating
- [ ] Inspect Zarf package (`zarf package inspect`)
- [ ] Inspect UDS bundle images (`uds inspect --list-images`)
- [ ] Validate compliance with Lula (`uds lula validate`)
- [ ] Verify MinIO configuration and secrets
- [ ] Check for Pepr policy violations (`kubectl logs -n pepr-system`)
- [ ] Verify registry access by pulling packages/bundles
- [ ] Review GitLab pipeline logs and artifacts for validation results

## Requesting Pepr Exception
- [ ] Identify Pepr policy violations during deployment attempt or pipeline integration stage
- [ ] Document justification for exception (package, policy, reason, mitigations)
- [ ] Submit exception request to Mission Lab admins via GitLab issue or email
- [ ] Include SBOM and Lula validation results from GitLab Artifacts
- [ ] Specify temporary or permanent exception duration
- [ ] Verify exception applied by redeploying package/bundle via pipeline or manually

## Testing
- [ ] Deploy package/bundle to local cluster (`zarf package deploy` or `uds deploy`)
- [ ] Test MinIO storage functionality
- [ ] Test Tenjin/Koverse AI workflows (if applicable)
- [ ] Verify pod status (`kubectl get all -n mission-lab`)
- [ ] Test Pepr exception functionality (if applicable)
- [ ] Test registry access by pulling and deploying from company registry
- [ ] Simulate air-gapped deployment for disconnected testing using GitLab Artifacts

## Deploying to Mission Lab
- [ ] For connected environments, deploy from registry (`uds deploy oci://<registry-url> --confirm`)
- [ ] For disconnected environments:
  - [ ] Transfer Zarf CLI, UDS CLI, `zarf init`, and bundle to air-gapped machine
  - [ ] Initialize cluster (`zarf init`)
  - [ ] Deploy bundle (`uds deploy --confirm`)
- [ ] Verify deployment (`kubectl get all -n mission-lab`)
- [ ] Confirm MinIO, Tenjin, and Koverse functionality in Mission Lab

## Post-Deployment
- [ ] Monitor application performance
- [ ] Update packages/bundles as needed (`zarf package create`, `uds create`)
- [ ] Document issues, configurations, Pepr exceptions, and registry details in the Git repository
```

## Best Practices
- **Security**: Use Lula for compliance, include SBOMs, and secure registry credentials. Justify Pepr exceptions with strong mitigations.
- **Modularity**: Leverage UDS functional layers for resource-constrained environments.
- **Version Control**: Maintain `zarf.yaml`, `uds-bundle.yaml`, Pepr exception documentation, pipeline configurations, and registry configurations in your GitLab repository.
- **Registry Management**: Regularly update credentials and rotate tokens for security. Use specific repository paths (e.g., `<registry-url>/mission-lab`) for organization.
- **Pepr Exceptions**: Request exceptions only when necessary and for the shortest duration possible.
- **CI/CD Pipelines**: Regularly review GitLab pipeline logs and artifacts for issues. Ensure container scanning and Pepr scans pass before publishing.
- **Documentation**: Update the checklist and README with registry access details, Pepr exceptions, pipeline configurations, and specific configurations.
- **Air-Gapped Deployments**: Test in a simulated disconnected environment before deploying to Mission Lab.

## References
- [Zarf Documentation](https://docs.zarf.dev/)
- [UDS Documentation](https://uds.defenseunicorns.com/)
- [MinIO Kubernetes Documentation](https://min.io/docs/minio/kubernetes/)
- [SAIC Tenjin and Koverse](https://www.saic.com/)
- [Pepr Documentation](https://pepr.dev/)
- Example Repository: [zarf-hello-world](https://github.com/millerjem/zarf-hello-world/tree/feature-annotations)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)

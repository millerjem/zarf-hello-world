# Mission Lab Deployment Checklist

## Prerequisites
- [ ] Install Zarf CLI (`brew install zarf`)
- [ ] Install UDS CLI (`brew install defenseunicorns/tap/uds`)
- [ ] Set up a Kubernetes cluster (e.g., k3s, k3d)
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

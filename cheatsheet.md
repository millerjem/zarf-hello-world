# Mission Lab Deployment Cheatsheet

| **Phase** | **Steps** | **Tools/Commands** | **Key Notes** |
|-----------|-----------|--------------------|---------------|
| **Prerequisites** | - Set up Kubernetes cluster<br>- Install Zarf/UDS CLI<br>- Configure MinIO, Tenjin/Koverse<br>- Access GitLab repo & registry<br>- Understand Pepr policies | - `brew install zarf`<br>- `brew install defenseunicorns/tap/uds`<br>- GitLab: `https://gitlab.company.com/mission-lab` | - Ensure registry credentials<br>- Verify Mission Lab access<br>- Set up GitLab Runner |
| **Create Zarf Packages** | - Define `zarf.yaml`<br>- Include MinIO/Tenjin configs<br>- Add UDS Custom Resource | - `zarf.yaml` for podinfo<br>- `minio-secret.yaml` for storage | - Encapsulate images, charts, manifests<br>- Support air-gapped deployments |
| **Build Zarf Packages** | - Create package<br>- Generate SBOM<br>- Sign package | - `zarf package create`<br>- `zarf package create --sbom`<br>- `zarf package create --sign` | - Produces tarball (e.g., `zarf-package-podinfo-<arch>-0.0.1.tar.zst`)<br>- Use Cosign for integrity |
| **Create UDS Bundles** | - Define `uds-bundle.yaml`<br>- Include Zarf packages<br>- Add service packages | - `uds create`<br>- Include `init`, `core`, `minio` | - Combines multiple Zarf packages<br>- Produces tarball (e.g., `uds-bundle-mission-lab-bundle-<arch>-0.0.1.tar.zst`) |
| **GitLab CI/CD Pipeline** | - Clone repo<br>- Push changes<br>- Monitor pipeline<br>- Access artifacts | - `git clone https://gitlab.company.com/mission-lab/<repository-name>.git`<br>- `git push origin main` | - **Validation**: Pre-commits, OSCAL scans<br>- **Build**: Package/SBOM creation<br>- **Integration**: Container/Pepr scans, deploy, tests<br>- **Cleanup**: Remove resources<br>- **Publish**: Push to registry (no critical/high CVEs) |
| **Access Registry** | - Authenticate CLI<br>- Push packages/bundles<br>- Pull for deployment<br>- Air-gapped: Transfer tarballs | - `zarf tools registry login <registry-url>`<br>- `uds publish oci://<registry-url>/mission-lab:0.0.1`<br>- `uds pull oci://<registry-url>/mission-lab:0.0.1` | - Use OCI-compliant registry (e.g., Harbor)<br>- Include credentials in `zarf.yaml` for air-gapped |
| **Validate** | - Inspect packages/bundles<br>- Check compliance<br>- Verify MinIO/registry | - `zarf package inspect`<br>- `uds inspect --list-images`<br>- `uds lula validate` | - Ensure Pepr compliance<br>- Review pipeline logs/artifacts |
| **Request Pepr Exception** | - Identify violations<br>- Submit request<br>- Apply exception<br>- Verify deployment | - `kubectl logs -n pepr-system <pepr-pod>`<br>- Submit via GitLab issue<br>- Update `pepr-exemption` ConfigMap | - Justify with mitigations<br>- Include SBOM, Lula results<br>- Specify duration |
| **Test** | - Local deployment<br>- Test MinIO/Tenjin<br>- Verify pods<br>- Test air-gapped | - `zarf package deploy`<br>- `uds deploy`<br>- `kubectl get all -n mission-lab` | - Use pipeline test results<br>- Simulate air-gapped environment |
| **Deploy** | - Connected: Deploy from registry<br>- Disconnected: Transfer & deploy<br>- Verify deployment | - `uds deploy oci://<registry-url>/mission-lab:0.0.1 --confirm`<br>- `zarf init`<br>- `uds deploy <bundle-tarball> --confirm` | - Confirm MinIO, Tenjin, Koverse functionality<br>- Check resources with `kubectl` |
| **Post-Deployment** | - Monitor performance<br>- Update packages/bundles<br>- Document issues | - Update `zarf.yaml`, `uds-bundle.yaml`<br>- Commit to GitLab | - Maintain configs in GitLab<br>- Rotate registry credentials |

## Best Practices
- **Security**: Use Lula, SBOMs, secure credentials, justify Pepr exceptions.
- **CI/CD**: Monitor pipeline, ensure no critical/high CVEs, use artifacts.
- **Air-Gapped**: Test disconnected deployments, transfer via secure media.
- **Documentation**: Update GitLab repo with configs, exceptions, pipeline details.

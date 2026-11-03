# Private Docker Registry

## Objective

Store and distribute the Portfolio Website Docker image using the private Docker Registry provided by the KodeKloud CI/CD Sandbox.

The workflow covers registry connectivity, authentication, image tagging, pushing, pulling, and deploying an image retrieved from the registry.

## Registry Architecture

| Component | Description |
|---|---|
| Registry | Self-hosted Docker Registry |
| Registry Image | registry:2.7.0 |
| Registry Host | docker-host |
| Registry Port | 5000 |
| Registry Endpoint | docker-host:5000 |
| Authentication | Username and password |
| Local Image | devops-portfolio:v1 |
| Registry Image | docker-host:5000/devops-portfolio:v1 |

## Registry Connectivity

Verify registry DNS:

    getent hosts docker-host

Verify TCP connectivity:

    nc -vz -w 5 docker-host 5000

The registry endpoint requires authentication. An unauthenticated request to its HTTPS API returns HTTP 401 Unauthorized.

## Registry Authentication

Authenticate using Docker CLI:

    docker login docker-host:5000 --username dock_user

Enter the registry password when prompted.

Expected result:

    Login Succeeded

Docker stores authentication configuration in:

    /root/.docker/config.json

The sandbox Docker CLI warned that credentials are stored unencrypted. For CI/CD integration, registry credentials should be stored in Jenkins Credentials rather than hardcoded in pipeline scripts.

## Image Tagging

Tag the local image for the private registry:

    docker tag devops-portfolio:v1 docker-host:5000/devops-portfolio:v1

Verify both tags:

    docker images | grep devops-portfolio

Both tags refer to the same image ID.

## Push Image

Push the image to the private registry:

    docker push docker-host:5000/devops-portfolio:v1

The push completed successfully.

Registry digest:

    sha256:83de4bacabe95f008260c23791e4918db2f869800cc8b5ca50ce788f888c90f5

## Pull Image

Remove the registry-specific local tag:

    docker image rm docker-host:5000/devops-portfolio:v1

Pull the image again:

    docker pull docker-host:5000/devops-portfolio:v1

The pull completed successfully.

Verify the image:

    docker images docker-host:5000/devops-portfolio

Inspect its image ID and runtime user:

    docker image inspect docker-host:5000/devops-portfolio:v1 --format 'ID: {{.Id}} | User: {{.Config.User}}'

Verified image ID:

    sha256:398a3ee225f409b8336ce490dfd50f522f9e8ae0fb4139169903157ba2b8520e

Runtime user:

    nginx

## Deployment Test

Run a test container using the registry image:

    docker run -d \
      --name devops-portfolio-registry-test \
      --network bridge \
      docker-host:5000/devops-portfolio:v1

Verify the container:

    docker ps --filter name=devops-portfolio-registry-test

Verify the runtime user:

    docker exec devops-portfolio-registry-test id

Expected result:

    uid=101(nginx) gid=101(nginx)

### HTML Verification

    docker exec devops-portfolio-registry-test \
      wget -S -O /dev/null http://127.0.0.1:8080/

Expected HTTP status: 200 OK.

### CSS Verification

    docker exec devops-portfolio-registry-test \
      wget -S -O /dev/null \
      http://127.0.0.1:8080/css/style.css

Expected HTTP status: 200 OK.

Both HTML and CSS returned HTTP 200 when tested inside the container deployed from the registry image.

## Cleanup

Remove the temporary test container:

    docker rm -f devops-portfolio-registry-test

The original devops-portfolio container remains running.

## Troubleshooting

### Registry Authentication Failure

Problem: Docker login returned HTTP 401 Unauthorized.

Resolution: Verify the registry username and password supplied by the sandbox. Use the interactive Docker login prompt and avoid passing passwords directly in shell commands.

### Registry Endpoint Response

Problem: An unauthenticated HTTP request returned an unexpected HTTP/0.9 response.

Investigation: HTTPS access to the registry API returned HTTP 401 Unauthorized, and TCP connectivity to port 5000 succeeded.

Conclusion: The registry was reachable and required authentication.

### Docker Credential Storage

Problem: Docker warned that credentials were stored unencrypted.

Resolution: For future CI/CD pipelines, store registry credentials in Jenkins Credentials and inject them during pipeline execution.

## Completion Criteria

- [x] Registry DNS resolution verified.
- [x] Registry TCP connectivity verified.
- [x] Registry authentication successful.
- [x] Local image tagged for the registry.
- [x] Image pushed successfully.
- [x] Image pulled successfully.
- [x] Image ID verified after pull.
- [x] Registry image deployed in a new container.
- [x] Non-root runtime user verified.
- [x] HTML returned HTTP 200.
- [x] CSS returned HTTP 200.
- [x] Test container cleaned up.

## Conclusion

The Portfolio Website image was successfully published to and retrieved from the private Docker Registry provided by the KodeKloud CI/CD Sandbox.

A new container was deployed using the registry image and verified successfully. Nginx served both HTML and CSS resources with HTTP 200 while running as the non-root nginx user.

The private registry is now ready to be integrated into the Jenkins CI/CD pipeline.

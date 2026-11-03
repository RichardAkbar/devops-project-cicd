# Dockerization

## Objective

Containerize the static Portfolio Website using Docker and Nginx. The application is packaged into a Docker image and served through Nginx.

The container follows basic security practices, including non-root execution, non-privileged port usage, and temporary directories under /tmp.

## Architecture

| Component | Description |
|---|---|
| Application | Static HTML and CSS Portfolio Website |
| Container Runtime | Docker Engine |
| Base Image | nginx:stable-alpine |
| Web Server | Nginx |
| Internal Port | 8080 |
| Container User | nginx (UID 101) |
| Network | Docker bridge |

Application files:

- app/index.html
- app/css/style.css

Nginx serves the application from /usr/share/nginx/html.

## Dockerfile Configuration

### Base Image and Package Updates

The Dockerfile uses nginx:stable-alpine as its base image.

The apk upgrade command updates available Alpine packages during image construction.

### Nginx Configuration

The Dockerfile modifies the default Nginx configuration:

- Removes the default user directive.
- Changes the PID file location to /tmp/nginx.pid.
- Redirects access logs to stdout.
- Redirects error logs to stderr.
- Changes the listening port from 80 to 8080.
- Moves temporary directories under /tmp/nginx.

### Application Files

The Dockerfile copies the application files into the Nginx document root:

- app/index.html
- app/css/style.css

### Non-root Execution

The container runs using nginx (UID 101), instead of root.

Nginx listens on port 8080, which does not require privileged port binding.

## Image Build

Build the Docker image:

    docker build --no-cache --network=host -t devops-portfolio:v1 .

The --network=host option was required during image construction because Docker bridge DNS resolution encountered timeouts when accessing Alpine package repositories in the sandbox.

This option applies only to the build process. The application container uses Docker bridge networking at runtime.

Verify the image:

    docker images devops-portfolio

## Container Deployment

Run the application container:

    docker run -d \
      --name devops-portfolio \
      --restart unless-stopped \
      --network bridge \
      -p 8082:8080 \
      devops-portfolio:v1

Port mapping:

| Host Port | Container Port |
|---|---|
| 8082 | 8080 |

Verify the container:

    docker ps

Check container logs:

    docker logs devops-portfolio

Verify the runtime user:

    docker exec devops-portfolio id

Expected user:

    uid=101(nginx) gid=101(nginx)

## Testing and Verification

### Nginx Configuration

    docker exec devops-portfolio nginx -t

Expected result: syntax is ok and test is successful.

### Internal HTML Access

    docker exec devops-portfolio wget -S -O /dev/null http://127.0.0.1:8080/

Expected HTTP status: 200 OK.

### Internal CSS Access

    docker exec devops-portfolio wget -S -O /dev/null http://127.0.0.1:8080/css/style.css

Expected HTTP status: 200 OK.

### Docker Bridge Network Access

Test HTML access from another container:

    docker run --rm --network bridge curlimages/curl:latest -i http://172.17.0.2:8080/

Expected HTTP status: 200 OK.

Test CSS access:

    docker run --rm --network bridge curlimages/curl:latest -sS -o /dev/null -w 'CSS HTTP Status: %{http_code}\n' http://172.17.0.2:8080/css/style.css

Expected result: CSS HTTP Status: 200.

## Troubleshooting

### Docker Build DNS Resolution

Problem: Docker build failed because DNS resolution timed out when accessing Alpine package repositories through the default Docker bridge network.

Solution: Use --network=host during image construction.

### Host Port Conflict

Problem: Host port 8080 was already occupied by the sandbox terminal service (ttyd).

Solution: Map host port 8082 to container port 8080.

Host networking is not used for the application container because it would cause a port conflict with the existing sandbox service.

### Host Port Returns HTTP 404

Problem: Requests to http://127.0.0.1:8082/ returned 404 page not found.

Investigation:

- Docker port mapping was present.
- Docker proxy was listening on host port 8082.
- Requests from inside the container returned HTTP 200.
- Requests from another container through the Docker bridge returned HTTP 200.
- Nginx access logs did not show the host request.

Conclusion: Application and Nginx functionality were verified internally and through Docker bridge networking. Host-port access remained unresolved and may be affected by the sandbox routing layer.

## Evidence

Evidence to capture:

- Docker image build output.
- Running container from docker ps.
- Nginx configuration test.
- Non-root runtime user verification.
- HTTP 200 response for HTML and CSS.
- Docker bridge network connectivity test.

## Completion Criteria

- [x] Docker image built successfully.
- [x] Nginx configured to listen on port 8080.
- [x] Application files copied into the image.
- [x] Container runs as a non-root user.
- [x] Nginx configuration validated.
- [x] HTML returns HTTP 200 internally.
- [x] CSS returns HTTP 200 internally.
- [x] Application accessible from another container over Docker bridge.
- [ ] Host-port access verified through the sandbox.

## Conclusion

The Portfolio Website was successfully containerized using Docker and Nginx. The image uses a non-root runtime user and serves the application over port 8080.

HTML and CSS were successfully verified from inside the container and from another container on the Docker bridge network. Host-port access remains an environment-specific issue requiring further investigation.

# Running the Flutter Web frontend in Docker

This document explains how to build and run the Flutter web frontend inside Docker so you don't need Flutter or VS Code on the target machine.

Prerequisites
- Docker installed

Build + run (recommended, will build the web app inside Docker):

```bash
# from project root (d:\Flutproj)
# optionally set BASE_URL to point to your backend reachable from the browser/container.
Option A — build inside Docker (may fail if Flutter SDK inside image doesn't match project SDK)

```bash
# from project root (d:\Flutproj)
export BASE_URL=http://host.docker.internal:8000
docker compose -f docker-compose.frontend.yml up --build -d
```

Option B — build locally and use a static nginx image (recommended for demo environments without Flutter)

1. Build Flutter web locally on your machine (requires Flutter installed):

```bash
cd clothing_app
flutter pub get
flutter build web --release --dart-define=BASE_URL=http://host.docker.internal:8000
cd ..
```

2. Build and run static nginx image that serves `build/web`:

```bash
docker build -f clothing_app/Dockerfile.static -t flutproj-frontend-static .
docker run -d --name flutproj-frontend-static -p 8080:80 flutproj-frontend-static
```

3. Open http://localhost:8080
```

Open http://localhost:8080 in a browser to see the web app.

Notes
- We made `lib/config.dart` read `BASE_URL` from compile-time `--dart-define`. The Docker build uses the build-arg `BASE_URL` to pass through this value.
- If you run Docker on Windows, `host.docker.internal` lets the container reach the host's `localhost:8000` backend. If your Docker environment differs, set `BASE_URL` to the backend address reachable from the container (for example `http://backend:8000` if using a single compose network).

Rollback
- To revert changes, remove the files added: `clothing_app/Dockerfile`, `clothing_app/nginx.conf`, `docker-compose.frontend.yml`, `clothing_app/README_FRONTEND_DOCKER.md`, and restore `lib/config.dart` to the previous literal `baseUrl` value.

Note: If the Flutter SDK version inside the Docker image doesn't match the project's required Dart SDK (see error about required SDK ^3.11.3), Option B is the fastest workaround: build web locally and use `Dockerfile.static` to serve it.

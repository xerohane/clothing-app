# Multi-stage Dockerfile to build Flutter web and serve via nginx
# Stage 1: build the web app using a Flutter SDK image
FROM cirrusci/flutter:stable AS builder
WORKDIR /app

# Copy sources
COPY . .

# Install minimal tools needed by `pub get` (git, unzip) and ensure certificates
RUN apt-get update \
  && apt-get install -y --no-install-recommends git ca-certificates unzip xz-utils curl \
  && rm -rf /var/lib/apt/lists/*

# Ensure dependencies and build web. Use BASE_URL via --dart-define when building image.
RUN flutter pub get
# Build will be executed during image build with --build-arg BASE_URL if provided
ARG BASE_URL
RUN if [ -z "$BASE_URL" ]; then \
      flutter build web --release; \
    else \
      flutter build web --release --dart-define=BASE_URL=$BASE_URL; \
    fi

# Stage 2: serve with nginx
FROM nginx:stable-alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

# Minimal nginx config: serve static files and allow websocket upgrades
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

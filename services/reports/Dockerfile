FROM rust:1.98.1-slim AS build
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --locked --release
FROM debian:trixie-slim
RUN useradd --uid 10001 --create-home reports
COPY --from=build /build/target/release/atlas-reports /usr/local/bin/atlas-reports
USER 10001:10001
EXPOSE 8080
CMD ["atlas-reports"]

# Build LibreSpeed (speedtest-go) from a pinned upstream release.
# speedtest-go is a single Go binary with the web frontend embedded, so the
# final image is just the binary plus our settings.toml.
FROM golang:1.25-alpine AS build

RUN apk add --no-cache git
WORKDIR /src

# Pin to a released tag for reproducible builds. Bump this to update LibreSpeed.
ARG SPEEDTEST_VERSION=v1.1.6
RUN git clone --depth 1 --branch ${SPEEDTEST_VERSION} \
        https://github.com/librespeed/speedtest-go.git .

# Static, dependency-free binary (CA roots are compiled in via breml/rootcerts).
ENV CGO_ENABLED=0
RUN go build -ldflags "-w -s" -trimpath -buildvcs=false -o /speedtest .

FROM scratch
WORKDIR /app
COPY --from=build /speedtest ./speedtest
# speedtest-go loads `settings.toml` from its working directory.
COPY settings.toml ./settings.toml

EXPOSE 8989
CMD ["./speedtest"]

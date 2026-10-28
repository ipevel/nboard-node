VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
BUILD_TIME ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS := -s -w -X main.version=$(VERSION) -X main.buildTime=$(BUILD_TIME) -X main.commit=$(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)

.PHONY: build clean test docker install build-linux build-linux-arm64 build-all

# Build for current platform
build:
	go build -ldflags "$(LDFLAGS)" -tags "with_quic with_utls with_wireguard with_clash_api" -o nboard-node ./cmd/nboard-node
	go build -ldflags "$(LDFLAGS)" -o nbctl ./cmd/nbctl

# Build for Linux amd64
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -tags "with_quic with_utls with_wireguard with_acme with_clash_api" -o nboard-node-linux-amd64 ./cmd/nboard-node
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o nbctl-linux-amd64 ./cmd/nbctl

# Build for Linux arm64
build-linux-arm64:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -tags "with_quic with_utls with_wireguard with_acme with_clash_api" -o nboard-node-linux-arm64 ./cmd/nboard-node
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -ldflags "$(LDFLAGS)" -o nbctl-linux-arm64 ./cmd/nbctl

# Build all platforms
build-all: build-linux build-linux-arm64

# Run tests
test:
	go test -v -race -count=1 ./internal/...

# Clean build artifacts
clean:
	rm -f nboard-node nbctl nboard-node-linux-* nbctl-linux-*

# Build Docker image
docker:
	docker build -t nboard-node:$(VERSION) -t nboard-node:latest .

# Install to system (single node, legacy compat)
install: build
	sudo cp nboard-node /usr/local/bin/
	sudo cp nbctl /usr/local/bin/
	sudo mkdir -p /etc/nboard-node
	@if [ ! -f /etc/nboard-node/config.yml ]; then \
		sudo cp config.yml.example /etc/nboard-node/config.yml; \
		echo "Config copied to /etc/nboard-node/config.yml - please edit it"; \
	fi

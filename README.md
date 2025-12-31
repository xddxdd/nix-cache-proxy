# Nix Cache Proxy

Request Nix binary caches in parallel. Speeds up Nix daemon's binary cache lookup requests.

## Building

```bash
cargo build --release
```

The compiled binary will be available at `target/release/nix-cache-proxy`.

## Usage

```bash
nix-cache-proxy [OPTIONS]

Options:
  -b, --bind <BIND>                  Bind address [default: 127.0.0.1:8080]
  -u, --upstream <UPSTREAM>          Upstream cache URLs (repeatable) [default: https://cache.nixos.org]
  -t, --timeout-secs <TIMEOUT_SECS>  Request timeout in seconds [default: 5]
  -h, --help                         Print help
```

### Example

```bash
./nix-cache-proxy \
  --bind 127.0.0.1:3000 \
  --upstream https://cache.nixos.org \
  --upstream https://attic.xuyh0120.win/lantian
```

## Listener Types

### TCP Socket (Default)

Standard TCP/IP socket binding. Supports both IPv4 and IPv6.

```bash
# IPv4
./nix-cache-proxy --bind 127.0.0.1:8080

# IPv6
./nix-cache-proxy --bind "[::1]:8080"
```

### Unix Socket

Listen on a Unix domain socket. The socket file is automatically cleaned up on startup and shutdown.

```bash
./nix-cache-proxy --bind unix:/run/nix-cache-proxy/nix-cache-proxy.sock
```

### Systemd Socket Activation

Accept connections from systemd socket units.

**Socket unit** (`/etc/systemd/system/nix-cache-proxy.socket`):
```ini
[Unit]
Description=Nix Cache Proxy Socket

[Socket]
ListenStream=8080

[Install]
WantedBy=sockets.target
```

**Service unit** (`/etc/systemd/system/nix-cache-proxy.service`):
```ini
[Unit]
Description=Nix Cache Proxy
Requires=nix-cache-proxy.socket

[Service]
Type=simple
ExecStart=/path/to/nix-cache-proxy --bind systemd --upstream https://cache.nixos.org

[Install]
WantedBy=multi-user.target
```

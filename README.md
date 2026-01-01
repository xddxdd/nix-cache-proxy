# Nix Cache Proxy

A simple proxy server that request multiple Nix binary caches in parallel. Helps speeding up Nix daemon's binary cache lookup requests, especially with many binary caches, since Nix daemon looks them up one by one.

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

## NixOS Module

This project provides a NixOS module for easy integration into NixOS configurations.

### Adding to Your Flake

Add `nix-cache-proxy` to your flake inputs, `inputs.nix-cache-proxy.overlays.default` to your overlays, and import `inputs.nix-cache-proxy.nixosModules.nix-cache-proxy` module:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-cache-proxy.url = "github:xddxdd/nix-cache-proxy";
  };

  outputs = { self, nixpkgs, nix-cache-proxy, ... }: {
    nixosConfigurations.your-hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        nix-cache-proxy.nixosModules.nix-cache-proxy
        {
          nixpkgs.overlays = [ nix-cache-proxy.overlays.default ];
          services.nix-cache-proxy.enable = true;
        }
      ];
    };
  };
}
```

### Configuration Options

The module provides the following options under `services.nix-cache-proxy`:

- **`enable`**: Enable the Nix Cache Proxy service (default: `false`)
- **`package`**: Package to use (default: `pkgs.nix-cache-proxy`)
- **`listenAddress`**: Listen address (default: `"127.0.0.1:8080"`)
  - Examples: `"127.0.0.1:8080"`, `"[::1]:8080"`, `"unix:/run/nix-cache-proxy/nix-cache-proxy.sock"`
- **`upstreams`**: List of upstream cache URLs (default: `["https://cache.nixos.org"]`)
- **`timeoutSecs`**: Request timeout in seconds (default: `5`)
- **`setNixSubstituter`**: Automatically configure Nix daemon to use the proxy (default: `true`)
  - Only supports IPv4/IPv6 listeners, not Unix sockets

### Examples

```nix
{
  services.nix-cache-proxy = {
    enable = true;
    listenAddress = "127.0.0.1:3000";
    upstreams = [
      "https://cache.nixos.org"
      "https://attic.xuyh0120.win/lantian"
    ];
    timeoutSecs = 5;
  };
}
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

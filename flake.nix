{
  description = "Nix binary cache proxy server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ self, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        systems = [
          "x86_64-linux"
          "aarch64-linux"
        ];

        flake = {
          nixosModules.nix-cache-proxy = ./module.nix;
          overlay = self.overlays.default;
          overlays = {
            default = final: prev: {
              nix-cache-proxy = self.packages.${final.stdenv.hostPlatform.system}.default;
            };
          };

          # Example configurations for testing package
          nixosConfigurations.test = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.nix-cache-proxy
              {
                nixpkgs.overlays = [ self.overlays.default ];
                services.nix-cache-proxy.enable = true;

                # Minimal config to make test configuration build
                boot.loader.grub.devices = [ "/dev/vda" ];
                fileSystems."/" = {
                  device = "tmpfs";
                  fsType = "tmpfs";
                };
                system.stateVersion = lib.trivial.release;
              }
            ];
          };
        };

        perSystem =
          { pkgs, ... }:
          {
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                cargo
                rustc
                rust-analyzer
                clippy
                rustfmt
                cargo-watch
                cargo-edit
              ];

              RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
            };

            packages.default = pkgs.rustPlatform.buildRustPackage (finalAttrs: {
              pname = "nix-cache-proxy";
              version = "0.1.0";
              src = ./.;
              cargoLock.lockFile = ./Cargo.lock;

              meta = {
                mainProgram = finalAttrs.pname;
                maintainers = with lib.maintainers; [ xddxdd ];
                description = "Proxy for Nix Binary Cache";
                homepage = "https://github.com/xddxdd/nix-cache-proxy";
                license = lib.licenses.gpl3Plus;
              };
            });
          };
      }
    );
}

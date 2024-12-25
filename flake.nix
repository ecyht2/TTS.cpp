{
  description = "TTS support with GGML.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # https://discourse.nixos.org/t/get-nix-flake-to-include-git-submodule/30324/20
    self.submodules = true;
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    # https://zero-to-nix.com/concepts/flakes/
    # The set of systems to provide outputs for
    allSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

    # Taken from https://github.com/numtide/flake-utils
    # A function that provides a system-specific Nixpkgs for the desired systems
    forAllSystems = eachSystem allSystems;
    # Builds a map from <attr>=value to <attr>.<system>=value for each system.
    eachSystem = eachSystemOp (
      # Merge outputs for each system.
      f: attrs: system: let
        ret = f system;
      in
        builtins.foldl' (
          attrs: key:
            attrs
            // {
              ${key} =
                (attrs.${key} or {})
                // {
                  ${system} = ret.${key};
                };
            }
        )
        attrs (builtins.attrNames ret)
    );
    # Applies a merge operation accross systems.
    eachSystemOp = op: systems: f:
      builtins.foldl' (op f) {} (
        if !builtins ? currentSystem || builtins.elem builtins.currentSystem systems
        then systems
        else
          # Add the current system if the --impure flag is used.
          systems ++ [builtins.currentSystem]
      );
  in
    forAllSystems
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          # https://discourse.nixos.org/t/flakes-with-unfree-licenses/9405/6
          config.allowUnfree = true;
        };
      in let
        buildInputs = [
          pkgs.SDL2
        ];
        cudaBuildInputs = [
          # A temporary hack for reducing the closure size, remove once cudaPackages
          # have stopped using lndir: https://github.com/NixOS/nixpkgs/issues/271792
          pkgs.cudaPackages.cuda_cudart
        ];

        nativeBuildInputs = [
          pkgs.cmake
          pkgs.clang
        ];
        cudaNativeBuildInputs = [
          pkgs.cudatoolkit
        ];
      in {
        formatter = pkgs.writeShellApplication {
          name = "format.sh";

          runtimeInputs = [
            pkgs.alejandra
          ];

          text = ''
            echo "Formatting Nix Files"
            alejandra .
          '';
        };

        # https://wiki.nixos.org/wiki/Flakes#Super_fast_nix-shell
        devShells = let
          packages = [
            pkgs.lldb
            pkgs.clang-tools

            pkgs.python3
          ];
        in {
          fhs = pkgs.buildFHSEnv {
            name = "TTS.cpp";

            inherit packages;
            inherit buildInputs;
            inherit nativeBuildInputs;
          };
          nix-shell = pkgs.mkShell {
            name = "TTS.cpp";

            inherit packages;
            inherit buildInputs;
            inherit nativeBuildInputs;
          };

          # CUDA Shells
          fhs-cuda =
            (pkgs.buildFHSEnv {
              name = "ggml-basic";

              targetPkgs = _:
                packages
                ++ buildInputs
                ++ cudaBuildInputs
                ++ nativeBuildInputs
                ++ cudaNativeBuildInputs
                ++ [pkgs.gcc];

              extraOutputsToInstall = ["static"];

              # Adding nvvm from cuda
              extraBuildCommands = ''
                cp -r ${pkgs.cudatoolkit}/nvvm/ $out/usr/
              '';
            }).env;
          nix-shell-cuda = pkgs.mkShell {
            name = "ggml-basic";

            inherit packages;
            buildInputs = buildInputs ++ cudaBuildInputs;
            nativeBuildInputs = nativeBuildInputs ++ cudaNativeBuildInputs;

            shellHook = ''
              export CUDA_PATH="${pkgs.cudatoolkit}"
            '';
          };

          default = self.devShells."${system}".nix-shell;
        };

        packages = let
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./ggml/.
              ./src/.
              ./include/.
              ./examples/.
              ./cmake/.
              ./CMakeLists.txt
            ];
          };
        in {
          cpu = pkgs.stdenv.mkDerivation {
            pname = "TTS.cpp";
            version = "0.1.0";

            inherit buildInputs;
            nativeBuildInputs = nativeBuildInputs ++ [pkgs.git];

            inherit src;
          };

          default = self.packages."${system}".cpu;
        };
      }
    );
}

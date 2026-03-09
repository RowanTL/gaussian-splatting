{
  description = "Develop Shell with CUDA and python available";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      # forAllSystems = lib.genAttrs lib.systems.flakeExposed;
      system = "x86_64-linux";
    in
    {
      devShells."${system}".default = let
        pkgs = import nixpkgs {
          inherit system;

          config = {
            allowUnfree = true;
          };
        };
      in pkgs.mkShell {
        packages = [
          (pkgs.python3.withPackages (pypkgs: with pypkgs; [
            # torch
            # torchvision
            # torchaudio
            # plyfile
            # tqdm
            # joblib
            # opencv-python
            # numpy
          ]))
          pkgs.uv
          pkgs.colmapWithCuda
          pkgs.imagemagick
          pkgs.ffmpeg
        ];
        buildInputs = with pkgs; [
         git gitRepo gnupg autoconf curl
         procps gnumake util-linux m4 gperf unzip
         cudatoolkit linuxPackages.nvidia_x11
         libGLU libGL
         xorg.libXi xorg.libXmu freeglut
         xorg.libXext xorg.libX11 xorg.libXv xorg.libXrandr zlib 
         ncurses5 stdenv.cc binutils
         stdenv.cc.cc.lib
         # ninja
       ];

        env = lib.optionalAttrs pkgs.stdenv.isLinux {
          # Python libraries often load native shared objects using dlopen(3).
          # Setting LD_LIBRARY_PATH makes the dynamic library loader aware of libraries without using RPATH for lookup.
          LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
        };

        shellHook = ''
          export CUDA_PATH=${pkgs.cudatoolkit}
          export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib:${pkgs.stdenv.cc.cc.lib}/lib
          export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
          export EXTRA_CCFLAGS="-I/usr/include"


          unset PYTHONPATH
          uv sync
          . .venv/bin/activate
        '';
      };
    };
}

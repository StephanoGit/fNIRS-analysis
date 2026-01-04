{
  description = "Python Jupyter environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        # 1. Config to allow broken packages (needed for pydicom on MacOS/ARM)
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowBroken = true;
            allowUnsupportedSystem = true;
          };
        };

        python = pkgs.python3;

        mne-nirs = python.pkgs.buildPythonPackage rec {
          pname = "mne-nirs";
          version = "0.7.3";
          format = "pyproject";

          src = python.pkgs.fetchPypi {
            pname = "mne_nirs";
            inherit version;
            hash = "sha256-OnV9lmkBVhau66sy/i0Bqk5Z37dN7stfZYma6ukR/HI=";
          };

          nativeBuildInputs = with python.pkgs; [
            hatchling
            hatch-vcs
          ];

          propagatedBuildInputs = with python.pkgs; [
            mne
            numpy
            scipy
            h5io
            nilearn
            seaborn
            statsmodels
          ];

          doCheck = false;
        };

        mne-bids = python.pkgs.buildPythonPackage rec {
          pname = "mne-bids";
          version = "0.18.0";
          format = "pyproject";

          src = python.pkgs.fetchPypi {
            pname = "mne_bids";
            inherit version;
            hash = "sha256-nba76ryLRlzhfCNWrRFga4caARYFSGaiQTqbMTQhE0o=";
          };

          # === FIX START ===
          # Relax the strict version pin in pyproject.toml so it accepts the
          # version of hatchling provided by nixpkgs-unstable
          postPatch = ''
            substituteInPlace pyproject.toml \
              --replace "hatchling==1.26.3" "hatchling>=1.26.3"
          '';
          # === FIX END ===

          nativeBuildInputs = with python.pkgs; [
            hatchling
            hatch-vcs
          ];

          propagatedBuildInputs = with python.pkgs; [
            mne
            numpy
            scipy
            h5io
            nilearn
            seaborn
            statsmodels
          ];

          doCheck = false;
        };
        pyvistaqt = python.pkgs.buildPythonPackage rec {
          pname = "pyvistaqt";
          version = "0.11.3";
          format = "pyproject";

          src = python.pkgs.fetchPypi {
            inherit pname version;
            hash = "sha256-tFzOruUBOp+Y/sPF3hdfWviX86bFWL9lxgCggSwgvro=";
          };

          nativeBuildInputs = with python.pkgs; [
            setuptools
            wheel
            setuptools-scm
          ];

          propagatedBuildInputs = with python.pkgs; [
            pyvista
            qtpy
          ];

          doCheck = false;
        };

      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            (python.withPackages (
              ps: with ps; [
                jupyter
                numpy
                torch
                tqdm
                pandas
                ipython
                opencv4
                pycocotools
                pillow
                torchvision
                torchaudio
                torchsummary
                matplotlib
                kaggle
                mne
                qtpy
                pyvista
                pyqt6
                darkdetect
                # Our custom package
                mne-nirs
                mne-bids
                pyvistaqt
              ]
            ))
            pkgs.wget
            pkgs.git
          ];

          shellHook = ''
            echo "🐍 Python Jupyter environment loaded"
            echo "Run: jupyter notebook"
          '';
        };
      }
    );
}

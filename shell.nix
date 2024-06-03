# Cf: https://nixos.wiki/wiki/Rust

# Variable and Imports definition
let
  # Import overlay to install specific Rust versions
  rust_overlay = import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz");

  # Import the 24.05 stable Nixpkgs library
  # `import` and `fetchTarball` are both attributes of the `builtins` set that are also available in the global scope.
  # Hence instead of writing `builtins.fetchTarball` we can write `fetchTarball`
  # However `fetchurl` isn't in the global scope.
  pkgs = import
    (fetchTarball
      "https://github.com/nixos/nixpkgs/tarball/nixos-24.05"
    )
    { overlays = [ rust_overlay ]; };
  # # We could specify the Rust version manually like this, however we use a nice helper to import from our `rust-toolchain.toml` file
  #   rustChannel = "nightly";
  #   rustVersion = "latest";
  #   #rustVersion = "1.62.0";
  #   rust = pkgs.rust-bin.${rustChannel}.${rustVersion}.default.override {
  #     extensions = [
  #       "rust-src" # for rust-analyzer
  #       "rust-analyzer"
  # 	  "cargo"
  # 	  "rustc"
  # 	  "rustfmt"
  # 	  "clippy"
  # 	  "rust-docs"
  # 	  "miri"
  #     ];
  # 	targets = [
  # 		"x86_64-unknown-linux-gnu"
  # 		"wasm32-unknown-unknown"
  # 		"aarch64-unknown-linux-gnu"
  # 	];
  #   };

  # After importing the nixpkgs and applying the rust overlay we can customize our rust installation
  rust = (
    pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml
  );

in

# Put pkgs into scope
with pkgs;


# If an issue occur with the cross-compiler, we might have to search and try this again
# https://github.com/oxalica/rust-overlay/issues/87
# pkgs.callPackage (
# 	{ mkShell, stdenv }:

# Shell session Creation (with the build tooling necessary for our project)
# We could use `mkShell rec {` if needed to reference attributes created in the same set
mkShell {
  nativeBuildInputs = [
    pkg-config
    rust
    # Install this on your OS if you need VsCode Rust Analyzer to use clippy instead of cargo check
    #  Use the following setting in your VsCode if you want clippy to check your code on save:
    # "rust-analyzer.check.overrideCommand": [
    #    "cargo-clippy",
    #    "--workspace",
    #    "--message-format=json",
    #    "--all-targets"
    #],
    clippy
    cargo-make
    cargo-cache
    cargo-tarpaulin
    cargo-nextest
    typos
    cargo-udeps
    cargo-audit
    # Embedded
    flip-link
    probe-rs
    # To use lld
    llvmPackages.bintools
  ];
  buildInputs = [
    patchelf
    fontconfig
  ];

  LIBCLANG_PATH = "${libclang.lib}/lib";
  RUST_SRC_PATH = "${rust}/lib/rustlib/src/rust/library";

  CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER =
    let
      inherit (stdenv) cc;
    in
    "${cc}/bin/${cc.targetPrefix}cc";

  # Setting env var here can be tricky as sometimes Nix will override those in the previous package imports.
  # For common var like CC etc, please set them in the shellHook.

}


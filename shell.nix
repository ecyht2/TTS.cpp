{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "tts.cpp";
  packages = with pkgs; [
    lldb
    clang-tools
  ];
  nativeBuildInputs = with pkgs; [
    cmake
    gcc
  ];
  buildInputs = with pkgs; [];
}

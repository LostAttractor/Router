_:
{
  # Lorri
  services.lorri.enable = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # VSCode Server
  services.vscode-server.enable = true;
}
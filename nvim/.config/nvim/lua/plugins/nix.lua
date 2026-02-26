-- NixOS compatibility: mason cannot install binaries on NixOS.
--
-- This file detects NixOS via /etc/NIXOS and disables mason entirely.
-- On non-NixOS systems (where you use stow) this file is a no-op and
-- mason continues to work as normal.
--
-- The corresponding Nix packages are declared in nixos-config at:
--   users/gecko/home.nix -> programs.neovim.extraPackages

local is_nix = vim.uv.fs_stat("/etc/NIXOS") ~= nil
if not is_nix then
  return {}
end

  return {
    -- Disable mason: it downloads FHS-incompatible binaries that won't
    -- run on NixOS. LSP servers and tools are installed via Nix instead
    -- and are available in $PATH for lspconfig and conform.nvim to find.
    { "mason-org/mason.nvim",            enabled = false },
    { "mason-org/mason-lspconfig.nvim",  enabled = false },

    -- Disable treesitter auto-install. gcc is provided via extraPackages
    -- so parsers can still be compiled on demand with :TSInstall <lang>.
    {
      "nvim-treesitter/nvim-treesitter",
      opts = {
        ensure_installed = {},
      },
    },
  }

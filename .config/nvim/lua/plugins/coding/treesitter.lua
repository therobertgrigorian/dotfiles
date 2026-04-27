return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "yaml",
          "json",
          "jsonc",
          "toml",
          "lua",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "css",
          "bash",
          "markdown",
          "markdown_inline",
        },
      })
    end,
  },
}

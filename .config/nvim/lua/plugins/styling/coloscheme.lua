return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,  -- Load before other colorschemes
    config = function()
      vim.cmd.colorscheme "catppuccin-mocha"
    end
  }
}

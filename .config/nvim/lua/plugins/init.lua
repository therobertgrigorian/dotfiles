local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup({
  checker = { enabled = true },
  -- copilot.lua bundles a ~145MB multi-platform language server. Fetching those
  -- blobs during checkout takes longer than lazy's default 120s timeout and gets
  -- SIGTERM'd mid-clone. Keep the (small) partial clone, just give it more time.
  git = { timeout = 600 },
  spec = {
    { import = "plugins.coding" },
    { import = "plugins.editor" },
    { import = "plugins.styling" },
    { import = "plugins.helpers" },
  },
})

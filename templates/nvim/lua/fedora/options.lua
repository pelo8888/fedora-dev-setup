vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.scrolloff = 6
vim.opt.sidescrolloff = 8
vim.opt.signcolumn = "yes"

if vim.g.fedora_setup_nvim_extras == 1 then
  vim.opt.timeoutlen = 300
end

if vim.fn.executable("rg") == 1 then
  vim.opt.grepprg = "rg --vimgrep"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

if vim.fn.executable("fd") == 1 then
  vim.opt.path:append("**")
end

-- Uhuru OS - neovim: mipangilio ya msingi bila plugins (inafanya kazi bila mtandao)
local o = vim.opt
o.number = true
o.relativenumber = true
o.mouse = "a"
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.termguicolors = true
o.cursorline = true
o.scrolloff = 6
o.signcolumn = "yes"
o.updatetime = 300
o.undofile = true
o.splitright = true
o.splitbelow = true
o.wrap = false
if vim.fn.executable("xclip") == 1 or vim.fn.executable("wl-copy") == 1 then o.clipboard = "unnamedplus" end

vim.g.mapleader = " "
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "hifadhi" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "toka" })
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "faili" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

if not pcall(vim.cmd, "colorscheme habamax") then pcall(vim.cmd, "colorscheme desert") end

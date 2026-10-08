-- native message/cmdline redesign (0.12+). Everything the docs list as the
-- default is left out; a pager that fills the window is the only change, and
-- 'messagesopt' already defaults to the items this config keeps.
if vim.fn.has("nvim-0.13") == 1 then
	vim.opt.messagesopt:append("timeout:4000")
end
require("vim._core.ui2").enable({ msg = { pager = { height = 1 } } })

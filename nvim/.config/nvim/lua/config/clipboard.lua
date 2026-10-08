-- WSL2 has no display server and Windows owns the clipboard, so `+` only
-- reaches Windows through the interop binaries. Neovim autodetects
-- win32yank.exe, but its other Windows fallback probes `clip` and `powershell`
-- without the .exe suffix (provider/clipboard.vim), and WSL's interop PATH only
-- exposes `clip.exe`/`powershell.exe`. With no win32yank.exe installed,
-- autodetection falls through to "No clipboard tool" and every yank to `+` is
-- dropped, so declare the provider ourselves.
if vim.fn.has("wsl") == 1 then
	if vim.fn.executable("win32yank.exe") == 1 then
		-- What autodetection would pick anyway, stated explicitly: it handles CRLF
		-- itself and beats spawning powershell.exe on every paste.
		vim.g.clipboard = "win32yank"
	else
		-- Get-Clipboard returns CRLF, so strip the CR. `-replace` is used instead of
		-- .ToString() because it tolerates an empty clipboard ($null).
		local paste = {
			"powershell.exe",
			"-NoLogo",
			"-NoProfile",
			"-NonInteractive",
			"-c",
			'[Console]::Out.Write($(Get-Clipboard -Raw) -replace "`r", "")',
		}
		vim.g.clipboard = {
			name = "WslClipboard",
			copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
			paste = { ["+"] = paste, ["*"] = paste },
			cache_enabled = 0,
		}
	end
elseif vim.env.SSH_TTY then
	vim.g.clipboard = "osc52" -- terminal carries the copy outward
end

-- Over SSH keep the unnamed register local (OSC52 reads are unreliable, so copy
-- out explicitly with "+y), everywhere else mirror yanks into the system clipboard.
vim.opt.clipboard = vim.env.SSH_TTY and "" or "unnamedplus"

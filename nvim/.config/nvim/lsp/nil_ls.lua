return {
	cmd = { "nil" },
	filetypes = { "nix" },
	root_markers = { "flake.nix", ".git" },
	settings = {
		["nil"] = {
			nix = {
				flake = {
					autoArchive = true,
				},
			},
			formatting = {
				command = { "nixfmt" },
			},
		},
	},
}

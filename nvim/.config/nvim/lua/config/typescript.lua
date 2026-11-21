-- The settings both TypeScript servers need, so the two lsp/*.lua files that
-- configure them do not drift apart.
local M = {}

---@return table
function M.settings()
	return {
		-- Node ESM wants the extension on a relative import, and tsserver reuses
		-- the tsconfig's bundler resolution to decide it is optional. This is what
		-- makes an auto-import write ./thing.js rather than ./thing.
		preferences = {
			importModuleSpecifierEnding = "js",
			preferTypeOnlyAutoImports = true,
		},
		-- The hints are off by default, so the toggle had nothing to show in
		-- TypeScript.
		inlayHints = {
			parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
			parameterTypes = { enabled = true },
			variableTypes = { enabled = true },
			propertyDeclarationTypes = { enabled = false },
			functionLikeReturnTypes = { enabled = true },
			enumMemberValues = { enabled = true },
		},
	}
end

return M

-- Install with: pnpm add -g graphql-language-service-cli (provides graphql-lsp)
-- Reads .graphqlrc.yml / graphql.config.* to load the schema for completion + validation.
-- Scoped to `graphql` filetype only, so it adds no overhead to TS/JS buffers.

return {
	cmd = { "graphql-lsp", "server", "-m", "stream" },
	filetypes = { "graphql" },
	root_markers = { ".graphqlrc.yml", ".graphqlrc", "graphql.config.yml", "graphql.config.js" },
}

# Optional SilverBullet+ semantic search

Use when the user wants conceptual matches or related pages and the feature is already available. The APIs are supplied through `Library/Plus` after Space Lua loads. Do not install a library, enable a feature, or download models merely because the namespace is missing.

```sh
sb --space notes eval 'type(semanticSearch) == "table"' --json
sb --space notes eval 'semanticSearch.status()' --json
sb --space notes eval 'semanticSearch.search("soil drainage", {mode="hybrid", limit=10})' --json
sb --space notes eval 'semanticSearch.search("", {page="Garden Notes", limit=10})' --json
```

The response contains `results`, `status`, and `waitingForIndex`. Pending indexing is not an empty result. Each result has `page`, `pos`, `heading`, `excerpt`, and `score`; positions are UTF-16 offsets and scores are ranks, not probabilities. Read the referenced page context before making claims. `mode="words"` selects lexical matching. `status.revision` changes as indexed data changes. Check readiness with bounded retries when needed; report pending state if it persists.

Prefer an explicit page for related-page queries: the CLI runtime's current page need not be the page visible to the user. If unavailable, use SLIQ for structural questions or ordinary file reading for content, explaining the narrower coverage.

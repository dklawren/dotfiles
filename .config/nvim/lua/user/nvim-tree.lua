local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

local config_status_ok, nvim_tree_config = pcall(require, "nvim-tree.config")
if not config_status_ok then
  return
end

nvim_tree.setup {
  on_attach = on_attach,
}

local function on_attach(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mappings. feel free to modify or remove as you wish.
  -- begin_default_on_attach
  vim.keymap.set('n', '<c-]>', api.tree.change_root_to_node,          opts('cd'))
  vim.keymap.set('n', '<c-e>', api.node.open.replace_tree_buffer,     opts('open: in place'))
  vim.keymap.set('n', '<c-k>', api.node.show_info_popup,              opts('info'))
  vim.keymap.set('n', '<c-r>', api.fs.rename_sub,                     opts('rename: omit filename'))
  vim.keymap.set('n', '<c-t>', api.node.open.tab,                     opts('open: new tab'))
  vim.keymap.set('n', '<c-v>', api.node.open.vertical,                opts('open: vertical split'))
  vim.keymap.set('n', '<c-x>', api.node.open.horizontal,              opts('open: horizontal split'))
  vim.keymap.set('n', '<bs>',  api.node.navigate.parent_close,        opts('close directory'))
  vim.keymap.set('n', '<cr>',  api.node.open.edit,                    opts('open'))
  vim.keymap.set('n', '<tab>', api.node.open.preview,                 opts('open preview'))
  vim.keymap.set('n', '>',     api.node.navigate.sibling.next,        opts('next sibling'))
  vim.keymap.set('n', '<',     api.node.navigate.sibling.prev,        opts('previous sibling'))
  vim.keymap.set('n', '.',     api.node.run.cmd,                      opts('run command'))
  vim.keymap.set('n', '-',     api.tree.change_root_to_parent,        opts('up'))
  vim.keymap.set('n', 'a',     api.fs.create,                         opts('create'))
  vim.keymap.set('n', 'bmv',   api.marks.bulk.move,                   opts('move bookmarked'))
  vim.keymap.set('n', 'b',     api.tree.toggle_no_buffer_filter,      opts('toggle no buffer'))
  vim.keymap.set('n', 'c',     api.fs.copy.node,                      opts('copy'))
  vim.keymap.set('n', 'c',     api.tree.toggle_git_clean_filter,      opts('toggle git clean'))
  vim.keymap.set('n', '[c',    api.node.navigate.git.prev,            opts('prev git'))
  vim.keymap.set('n', ']c',    api.node.navigate.git.next,            opts('next git'))
  vim.keymap.set('n', 'd',     api.fs.remove,                         opts('delete'))
  vim.keymap.set('n', 'd',     api.fs.trash,                          opts('trash'))
  vim.keymap.set('n', 'e',     api.tree.expand_all,                   opts('expand all'))
  vim.keymap.set('n', 'e',     api.fs.rename_basename,                opts('rename: basename'))
  vim.keymap.set('n', ']e',    api.node.navigate.diagnostics.next,    opts('next diagnostic'))
  vim.keymap.set('n', '[e',    api.node.navigate.diagnostics.prev,    opts('prev diagnostic'))
  vim.keymap.set('n', 'f',     api.live_filter.clear,                 opts('clean filter'))
  vim.keymap.set('n', 'f',     api.live_filter.start,                 opts('filter'))
  vim.keymap.set('n', 'g?',    api.tree.toggle_help,                  opts('help'))
  vim.keymap.set('n', 'gy',    api.fs.copy.absolute_path,             opts('copy absolute path'))
  vim.keymap.set('n', 'h',     api.tree.toggle_hidden_filter,         opts('toggle dotfiles'))
  vim.keymap.set('n', 'i',     api.tree.toggle_gitignore_filter,      opts('toggle git ignore'))
  vim.keymap.set('n', 'j',     api.node.navigate.sibling.last,        opts('last sibling'))
  vim.keymap.set('n', 'k',     api.node.navigate.sibling.first,       opts('first sibling'))
  vim.keymap.set('n', 'm',     api.marks.toggle,                      opts('toggle bookmark'))
  vim.keymap.set('n', 'o',     api.node.open.edit,                    opts('open'))
  vim.keymap.set('n', 'o',     api.node.open.no_window_picker,        opts('open: no window picker'))
  vim.keymap.set('n', 'p',     api.fs.paste,                          opts('paste'))
  vim.keymap.set('n', 'p',     api.node.navigate.parent,              opts('parent directory'))
  vim.keymap.set('n', 'q',     api.tree.close,                        opts('close'))
  vim.keymap.set('n', 'r',     api.fs.rename,                         opts('rename'))
  vim.keymap.set('n', 'r',     api.tree.reload,                       opts('refresh'))
  vim.keymap.set('n', 's',     api.node.run.system,                   opts('run system'))
  vim.keymap.set('n', 's',     api.tree.search_node,                  opts('search'))
  vim.keymap.set('n', 'u',     api.tree.toggle_custom_filter,         opts('toggle hidden'))
  vim.keymap.set('n', 'w',     api.tree.collapse_all,                 opts('collapse'))
  vim.keymap.set('n', 'x',     api.fs.cut,                            opts('cut'))
  vim.keymap.set('n', 'y',     api.fs.copy.filename,                  opts('copy name'))
  vim.keymap.set('n', 'y',     api.fs.copy.relative_path,             opts('copy relative path'))
  vim.keymap.set('n', '<2-leftmouse>',  api.node.open.edit,           opts('open'))
  vim.keymap.set('n', '<2-rightmouse>', api.tree.change_root_to_node, opts('cd'))
  -- end_default_on_attach

  -- mappings migrated from view.mappings.list
  -- you will need to insert "your code goes here" for any mappings with a custom action_cb
  vim.keymap.set('n', 'l', api.node.open.edit, opts('open'))
  vim.keymap.set('n', '<cr>', api.node.open.edit, opts('open'))
  vim.keymap.set('n', 'o', api.node.open.edit, opts('open'))
  vim.keymap.set('n', 'h', api.node.navigate.parent_close, opts('close directory'))
  vim.keymap.set('n', 'v', api.node.open.vertical, opts('open: vertical split'))
end

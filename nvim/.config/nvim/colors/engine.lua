-- [ENGINE] Neovim colorscheme
-- Nature-inspired palette · single source of truth via tokens.toml.
--
-- Mapping rationale (see /home/doodlebob/.claude/plans/glowing-tinkering-canyon.md):
--   Keywords / control flow → Royal Blue (primary)     — engineering depth
--   Types / classes          → Sky Blue (secondary)    — structural clarity
--   Strings                  → Lime Green (success)    — value-laden, "go"
--   Numbers / constants      → Golden Orange (tertiary) — warm signal
--   Functions / methods      → Mist Blue                — air, action
--   Comments                 → fg_muted (Weathered Sand) italic — soft, paper
--   Errors                   → Coral Red (error)
--   Warnings                 → Warm Honey
--   Info diagnostics         → Mist Blue
--   Hints                    → fg_muted

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end
vim.g.colors_name = "engine"
vim.o.background = "dark"
vim.o.termguicolors = true

local p = require("engine.palette")

-- Convenience: vim.api.nvim_set_hl with namespace 0 (global).
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- ===========================================================================
-- Editor core
-- ===========================================================================
hl("Normal",        { fg = p.fg,       bg = p.bg })
hl("NormalNC",      { fg = p.fg,       bg = p.bg })
hl("NormalFloat",   { fg = p.fg,       bg = p.bg_alt })
hl("FloatBorder",   { fg = p.primary,  bg = p.bg_alt })
hl("FloatTitle",    { fg = p.fg,       bg = p.bg_alt, bold = true })

hl("NonText",       { fg = p.inactive })
hl("EndOfBuffer",   { fg = p.bg })
hl("Whitespace",    { fg = p.inactive })
hl("Conceal",       { fg = p.fg_muted })

hl("Cursor",        { fg = p.bg,       bg = p.primary })
hl("lCursor",       { fg = p.bg,       bg = p.primary })
hl("CursorLine",    {                  bg = p.bg_alt })
hl("CursorColumn",  {                  bg = p.bg_alt })
hl("CursorLineNr",  { fg = p.primary,  bold = true })
hl("LineNr",        { fg = p.fg_muted })
hl("SignColumn",    {                  bg = p.bg })
hl("FoldColumn",    { fg = p.fg_muted })
hl("Folded",        { fg = p.fg_muted, bg = p.bg_alt, italic = true })

hl("VertSplit",     { fg = p.inactive })
hl("WinSeparator",  { fg = p.inactive })
hl("StatusLine",    { fg = p.fg,       bg = p.bg_alt })
hl("StatusLineNC",  { fg = p.fg_muted, bg = p.bg_alt })
hl("TabLine",       { fg = p.fg_muted, bg = p.bg_alt })
hl("TabLineSel",    { fg = p.fg,       bg = p.selection, bold = true })
hl("TabLineFill",   {                  bg = p.bg })
hl("WildMenu",      { fg = p.fg,       bg = p.selection })

hl("Title",         { fg = p.primary,  bold = true })
hl("Directory",     { fg = p.secondary })
hl("Question",      { fg = p.secondary })
hl("MoreMsg",       { fg = p.success })
hl("ModeMsg",       { fg = p.fg,       bold = true })
hl("WarningMsg",    { fg = p.honey })
hl("ErrorMsg",      { fg = p.error,    bold = true })

hl("Visual",        {                  bg = p.selection })
hl("VisualNOS",     {                  bg = p.selection })

hl("Search",        { fg = p.bg,       bg = p.honey })
hl("IncSearch",     { fg = p.bg,       bg = p.tertiary, bold = true })
hl("CurSearch",     { fg = p.bg,       bg = p.tertiary, bold = true })
hl("Substitute",    { fg = p.bg,       bg = p.success })
hl("MatchParen",    { fg = p.tertiary, bold = true, underline = true })

hl("SpecialKey",    { fg = p.fg_muted })
hl("ColorColumn",   {                  bg = p.bg_alt })

-- Popup menus (cmp, native completion)
hl("Pmenu",         { fg = p.fg,       bg = p.bg_alt })
hl("PmenuSel",      { fg = p.fg,       bg = p.selection, bold = true })
hl("PmenuSbar",     {                  bg = p.warm_shadow })
hl("PmenuThumb",    {                  bg = p.fg_muted })

-- Diff
hl("DiffAdd",       { fg = p.success,  bg = p.bg_alt })
hl("DiffChange",    { fg = p.tertiary, bg = p.bg_alt })
hl("DiffDelete",    { fg = p.error,    bg = p.bg_alt })
hl("DiffText",      { fg = p.fg,       bg = p.warm_shadow, bold = true })

-- Spell
hl("SpellBad",      { sp = p.error,    undercurl = true })
hl("SpellCap",      { sp = p.honey,    undercurl = true })
hl("SpellLocal",    { sp = p.secondary, undercurl = true })
hl("SpellRare",     { sp = p.wisteria, undercurl = true })

-- ===========================================================================
-- Legacy syntax groups (some plugins still use these)
-- ===========================================================================
hl("Comment",       { fg = p.fg_muted, italic = true })
hl("Constant",      { fg = p.tertiary })
hl("String",        { fg = p.success })
hl("Character",     { fg = p.success })
hl("Number",        { fg = p.tertiary })
hl("Float",         { fg = p.tertiary })
hl("Boolean",       { fg = p.tertiary, bold = true })

hl("Identifier",    { fg = p.fg })
hl("Function",      { fg = p.mist,     bold = true })

hl("Statement",     { fg = p.primary })
hl("Conditional",   { fg = p.primary,  bold = true })
hl("Repeat",        { fg = p.primary,  bold = true })
hl("Label",         { fg = p.primary })
hl("Operator",      { fg = p.fg })
hl("Keyword",       { fg = p.primary,  bold = true })
hl("Exception",     { fg = p.error,    bold = true })

hl("PreProc",       { fg = p.wisteria })
hl("Include",       { fg = p.wisteria })
hl("Define",        { fg = p.wisteria })
hl("Macro",         { fg = p.wisteria })
hl("PreCondit",     { fg = p.wisteria })

hl("Type",          { fg = p.secondary })
hl("StorageClass",  { fg = p.secondary, italic = true })
hl("Structure",     { fg = p.secondary, bold = true })
hl("Typedef",       { fg = p.secondary })

hl("Special",       { fg = p.tertiary })
hl("SpecialChar",   { fg = p.tertiary })
hl("Tag",           { fg = p.secondary })
hl("Delimiter",     { fg = p.fg_muted })
hl("SpecialComment", { fg = p.mist,    italic = true })
hl("Debug",         { fg = p.honey })

hl("Underlined",    { fg = p.secondary, underline = true })
hl("Ignore",        { fg = p.inactive })
hl("Error",         { fg = p.error,    bold = true })
hl("Todo",          { fg = p.bg,       bg = p.honey, bold = true })

-- ===========================================================================
-- TreeSitter (`:help treesitter-highlight`)
-- ===========================================================================
hl("@comment",                  { link = "Comment" })
hl("@comment.documentation",    { fg = p.mist,     italic = true })
hl("@comment.todo",             { link = "Todo" })
hl("@comment.warning",          { fg = p.bg,       bg = p.honey, bold = true })
hl("@comment.error",            { fg = p.bg,       bg = p.error, bold = true })
hl("@comment.note",             { fg = p.bg,       bg = p.secondary, bold = true })

hl("@keyword",                  { fg = p.primary,  bold = true })
hl("@keyword.return",           { fg = p.error,    bold = true })
hl("@keyword.exception",        { fg = p.error,    bold = true })
hl("@keyword.import",           { fg = p.wisteria })
hl("@keyword.operator",         { fg = p.primary })
hl("@keyword.function",         { fg = p.primary,  italic = true })

hl("@function",                 { fg = p.mist,     bold = true })
hl("@function.builtin",         { fg = p.mist,     italic = true })
hl("@function.call",            { fg = p.mist })
hl("@function.macro",           { fg = p.wisteria, italic = true })
hl("@function.method",          { fg = p.mist })
hl("@function.method.call",     { fg = p.mist })

hl("@constructor",              { fg = p.secondary, bold = true })
hl("@type",                     { fg = p.secondary })
hl("@type.builtin",             { fg = p.secondary, italic = true })
hl("@type.definition",          { fg = p.secondary, bold = true })
hl("@type.qualifier",           { fg = p.secondary, italic = true })

hl("@variable",                 { fg = p.fg })
hl("@variable.builtin",         { fg = p.tertiary, italic = true })
hl("@variable.parameter",       { fg = p.sand })
hl("@variable.member",          { fg = p.fg })

hl("@property",                 { fg = p.fg })
hl("@field",                    { fg = p.fg })

hl("@constant",                 { fg = p.tertiary, bold = true })
hl("@constant.builtin",         { fg = p.tertiary, italic = true })
hl("@constant.macro",           { fg = p.wisteria })

hl("@string",                   { fg = p.success })
hl("@string.escape",            { fg = p.tertiary, bold = true })
hl("@string.special",           { fg = p.tertiary })
hl("@string.regex",             { fg = p.honey })
hl("@string.documentation",     { fg = p.mist,     italic = true })

hl("@number",                   { fg = p.tertiary })
hl("@boolean",                  { fg = p.tertiary, bold = true })
hl("@character",                { fg = p.success })

hl("@operator",                 { fg = p.fg })
hl("@punctuation.delimiter",    { fg = p.fg_muted })
hl("@punctuation.bracket",      { fg = p.fg_muted })
hl("@punctuation.special",      { fg = p.tertiary })

hl("@attribute",                { fg = p.wisteria })
hl("@module",                   { fg = p.secondary })
hl("@namespace",                { fg = p.secondary })
hl("@label",                    { fg = p.primary })

hl("@tag",                      { fg = p.secondary })
hl("@tag.attribute",            { fg = p.tertiary })
hl("@tag.delimiter",            { fg = p.fg_muted })

hl("@markup.heading",           { fg = p.primary,  bold = true })
hl("@markup.heading.1",         { fg = p.primary,  bold = true })
hl("@markup.heading.2",         { fg = p.secondary, bold = true })
hl("@markup.heading.3",         { fg = p.tertiary, bold = true })
hl("@markup.heading.4",         { fg = p.success,  bold = true })
hl("@markup.italic",            { italic = true })
hl("@markup.bold",              { bold = true })
hl("@markup.strikethrough",     { strikethrough = true })
hl("@markup.underline",         { underline = true })
hl("@markup.link",              { fg = p.secondary, underline = true })
hl("@markup.link.url",          { fg = p.mist,     underline = true })
hl("@markup.list",              { fg = p.tertiary })
hl("@markup.quote",             { fg = p.fg_muted, italic = true })
hl("@markup.raw",               { fg = p.success,  bg = p.bg_alt })
hl("@markup.environment",       { fg = p.wisteria })

hl("@diff.plus",                { fg = p.success })
hl("@diff.minus",               { fg = p.error })
hl("@diff.delta",               { fg = p.tertiary })

-- ===========================================================================
-- LSP diagnostics (Neovim 0.10+)
-- ===========================================================================
hl("DiagnosticError",           { fg = p.error })
hl("DiagnosticWarn",            { fg = p.honey })
hl("DiagnosticInfo",            { fg = p.mist })
hl("DiagnosticHint",            { fg = p.fg_muted })
hl("DiagnosticOk",              { fg = p.success })

hl("DiagnosticUnderlineError",  { sp = p.error,    undercurl = true })
hl("DiagnosticUnderlineWarn",   { sp = p.honey,    undercurl = true })
hl("DiagnosticUnderlineInfo",   { sp = p.mist,     undercurl = true })
hl("DiagnosticUnderlineHint",   { sp = p.fg_muted, undercurl = true })

hl("DiagnosticVirtualTextError", { fg = p.error,    bg = p.bg_alt, italic = true })
hl("DiagnosticVirtualTextWarn",  { fg = p.honey,    bg = p.bg_alt, italic = true })
hl("DiagnosticVirtualTextInfo",  { fg = p.mist,     bg = p.bg_alt, italic = true })
hl("DiagnosticVirtualTextHint",  { fg = p.fg_muted, bg = p.bg_alt, italic = true })

hl("LspReferenceText",          { bg = p.selection })
hl("LspReferenceRead",          { bg = p.selection })
hl("LspReferenceWrite",         { bg = p.selection, bold = true })
hl("LspInlayHint",              { fg = p.fg_muted, italic = true, bg = p.bg_alt })

-- ===========================================================================
-- Git signs (Gitsigns plugin)
-- ===========================================================================
hl("GitSignsAdd",               { fg = p.success })
hl("GitSignsChange",            { fg = p.tertiary })
hl("GitSignsDelete",            { fg = p.error })
hl("GitSignsAddNr",             { fg = p.success })
hl("GitSignsChangeNr",          { fg = p.tertiary })
hl("GitSignsDeleteNr",          { fg = p.error })
hl("GitSignsAddLn",             { bg = p.bg_alt })
hl("GitSignsChangeLn",          { bg = p.bg_alt })
hl("GitSignsDeleteLn",          { bg = p.bg_alt })

-- ===========================================================================
-- Telescope
-- ===========================================================================
hl("TelescopeBorder",           { fg = p.primary,  bg = p.bg_alt })
hl("TelescopePromptBorder",     { fg = p.primary,  bg = p.bg_alt })
hl("TelescopeResultsBorder",    { fg = p.primary,  bg = p.bg_alt })
hl("TelescopePreviewBorder",    { fg = p.primary,  bg = p.bg_alt })
hl("TelescopePromptNormal",     { fg = p.fg,       bg = p.bg_alt })
hl("TelescopePromptPrefix",     { fg = p.tertiary, bg = p.bg_alt })
hl("TelescopeNormal",           { fg = p.fg,       bg = p.bg_alt })
hl("TelescopeSelection",        { fg = p.fg,       bg = p.selection, bold = true })
hl("TelescopeMatching",         { fg = p.tertiary, bold = true })
hl("TelescopeMultiSelection",   { fg = p.success })

-- ===========================================================================
-- neo-tree / nvim-tree
-- ===========================================================================
hl("NeoTreeNormal",             { fg = p.fg,       bg = p.bg })
hl("NeoTreeNormalNC",           { fg = p.fg,       bg = p.bg })
hl("NeoTreeDirectoryName",      { fg = p.secondary })
hl("NeoTreeDirectoryIcon",      { fg = p.secondary })
hl("NeoTreeFileName",           { fg = p.fg })
hl("NeoTreeFileIcon",           { fg = p.fg_muted })
hl("NeoTreeGitAdded",           { fg = p.success })
hl("NeoTreeGitModified",        { fg = p.tertiary })
hl("NeoTreeGitDeleted",         { fg = p.error })
hl("NeoTreeGitUntracked",       { fg = p.honey })
hl("NeoTreeRootName",           { fg = p.primary,  bold = true })

-- ===========================================================================
-- which-key / noice / mini.icons / Trouble
-- ===========================================================================
hl("WhichKey",                  { fg = p.tertiary })
hl("WhichKeyGroup",             { fg = p.primary })
hl("WhichKeyDesc",              { fg = p.fg })
hl("WhichKeySeparator",         { fg = p.fg_muted })
hl("WhichKeyFloat",             { bg = p.bg_alt })

hl("TroubleNormal",             { fg = p.fg,       bg = p.bg })
hl("TroubleText",               { fg = p.fg })
hl("TroubleCount",              { fg = p.tertiary, bg = p.bg_alt })

-- ===========================================================================
-- Indent guides
-- ===========================================================================
hl("IndentBlanklineChar",       { fg = p.inactive })
hl("IblIndent",                 { fg = p.inactive })
hl("IblScope",                  { fg = p.primary })

-- ===========================================================================
-- LSP semantic tokens (Liquid Retina v3) — richer language signal; the family
-- half-spokes add the purple/green/orange presence without moving the core
-- syntax semantics.
-- ===========================================================================
hl("@lsp.type.class",           { link = "@type" })
hl("@lsp.type.interface",       { fg = p.secondary, italic = true })
hl("@lsp.type.enum",            { link = "@type" })
hl("@lsp.type.enumMember",      { link = "@constant" })
hl("@lsp.type.struct",          { link = "@type" })
hl("@lsp.type.namespace",       { link = "@namespace" })
hl("@lsp.type.parameter",       { link = "@variable.parameter" })
hl("@lsp.type.property",        { link = "@property" })
hl("@lsp.type.variable",        { link = "@variable" })
hl("@lsp.type.macro",           { fg = p.lavender, italic = true })
hl("@lsp.type.decorator",       { fg = p.lavender })
hl("@lsp.type.keyword",         { link = "@keyword" })
hl("@lsp.type.lifetime",        { fg = p.orchid, italic = true })  -- Rust lifetimes
hl("@lsp.mod.deprecated",       { strikethrough = true })
hl("@lsp.typemod.function.defaultLibrary", { fg = p.mist, italic = true })

-- ===========================================================================
-- blink.cmp (LazyVim completion) + noice/notify (v3 gap fill)
-- ===========================================================================
hl("BlinkCmpMenu",              { fg = p.fg,       bg = p.bg_alt })
hl("BlinkCmpMenuBorder",        { fg = p.primary_400, bg = p.bg_alt })
hl("BlinkCmpMenuSelection",     { bg = p.selection, bold = true })
hl("BlinkCmpLabelMatch",        { fg = p.tertiary, bold = true })
hl("BlinkCmpDoc",               { fg = p.fg,       bg = p.bg_alt })
hl("BlinkCmpDocBorder",         { fg = p.primary_700, bg = p.bg_alt })
hl("BlinkCmpKind",              { fg = p.lavender })

hl("NotifyERRORBorder",         { fg = p.error })
hl("NotifyWARNBorder",          { fg = p.honey })
hl("NotifyINFOBorder",          { fg = p.jade })
hl("NotifyERRORIcon",           { fg = p.error })
hl("NotifyWARNIcon",            { fg = p.honey })
hl("NotifyINFOIcon",            { fg = p.jade })

-- ===========================================================================
-- snacks.nvim dashboard — the SLICEDLABS greeting inside the editor
-- ===========================================================================
hl("SnacksDashboardHeader",     { fg = p.lavender, bold = true })
hl("SnacksDashboardDesc",       { fg = p.fg })
hl("SnacksDashboardIcon",       { fg = p.tangerine })
hl("SnacksDashboardKey",        { fg = p.gold, bold = true })
hl("SnacksDashboardFooter",     { fg = p.fg_muted, italic = true })
hl("SnacksDashboardSpecial",    { fg = p.jade })

-- ===========================================================================
-- Terminal ANSI colors (used by :terminal)
-- ===========================================================================
vim.g.terminal_color_0  = p.ansi_black
vim.g.terminal_color_1  = p.ansi_red
vim.g.terminal_color_2  = p.ansi_green
vim.g.terminal_color_3  = p.ansi_yellow
vim.g.terminal_color_4  = p.ansi_blue
vim.g.terminal_color_5  = p.ansi_magenta
vim.g.terminal_color_6  = p.ansi_cyan
vim.g.terminal_color_7  = p.ansi_white
vim.g.terminal_color_8  = p.fg_muted
vim.g.terminal_color_9  = p.ansi_red
vim.g.terminal_color_10 = p.ansi_green
vim.g.terminal_color_11 = p.ansi_yellow
vim.g.terminal_color_12 = p.ansi_blue
vim.g.terminal_color_13 = p.ansi_magenta
vim.g.terminal_color_14 = p.ansi_cyan
vim.g.terminal_color_15 = p.fg

-- ===========================================================================
-- Identity accent — the focused workspace's hue ($SL_IDENTITY, exported by
-- scene.sh when this terminal was spawned) tints the CHROME (statusline, cursor-
-- line number, float borders, title), so nvim breathes the workspace identity.
-- Syntax + diagnostics keep their semantic colours; only the accent moves.
-- ===========================================================================
local accent = vim.env.SL_IDENTITY
if accent and accent:match("^#%x%x%x%x%x%x$") then
  hl("StatusLine",   { fg = p.bg, bg = accent, bold = true })
  hl("CursorLineNr", { fg = accent, bold = true })
  hl("FloatBorder",  { fg = accent, bg = p.bg_alt })
  hl("Title",        { fg = accent, bold = true })
end

if vim.g.loaded_beatdeck then return end
vim.g.loaded_beatdeck = true

local subs = { 'start', 'status', 'toggle', 'next', 'prev', 'play', 'list', 'vol' }

vim.api.nvim_create_user_command('Beatdeck', function(o)
  local bd = require('beatdeck')
  local cmd = o.fargs[1] or 'status'
  if not vim.tbl_contains(subs, cmd) then
    return vim.notify('beatdeck: unknown subcommand "' .. cmd .. '"', vim.log.levels.WARN)
  end
  local rest = o.args:match('^%s*%S+%s+(.-)%s*$') or ''
  bd[cmd](rest)
end, {
  nargs = '*',
  desc = 'beatdeck remote (status when called bare)',
  complete = function(lead, line)
    local sub, rest = line:match('^%S+%s+(%S+)%s+(.*)$')
    if not sub then
      return vim.tbl_filter(function(s) return s:find(lead, 1, true) == 1 end, subs)
    end
    if sub == 'play' or sub == 'list' then return require('beatdeck').complete(rest) end
    if sub == 'vol' then return { '25', '50', '75', '100' } end
    return {}
  end,
})

if vim.g.beatdeck_keymaps ~= false then
  local function map(lhs, rhs, desc)
    vim.keymap.set('n', '<leader>b' .. lhs, rhs, { desc = 'beatdeck: ' .. desc })
  end
  map('b', '<cmd>Beatdeck toggle<CR>', 'play/pause')
  map('n', '<cmd>Beatdeck next<CR>', 'next')
  map('p', '<cmd>Beatdeck prev<CR>', 'prev')
  map('l', '<cmd>Beatdeck list<CR>', 'pick a mix')
  map('f', ':Beatdeck play ', 'find and play (Tab completes)')
  map('s', '<cmd>Beatdeck status<CR>', 'status')
  map('S', '<cmd>Beatdeck start<CR>', 'start server')
end

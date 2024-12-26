local M = {}

local function is_percentage(number)
  return number > 0 and number < 1
end

local function create_floating_window(opts)
  opts = opts or {}

  local width
  if opts.width then
    if is_percentage(opts.width) then
      width = math.floor(vim.api.nvim_win_get_width(0) * opts.width)
    else
      width = opts.width
    end
  else
    width = math.floor(vim.api.nvim_win_get_width(0) * 0.8)
  end

  local height
  if opts.height then
    if is_percentage(opts.height) then
      height = math.floor(vim.api.nvim_win_get_height(0) * opts.height)
    else
      height = opts.height
    end
  else
    height = math.floor(vim.api.nvim_win_get_height(0) * 0.8)
  end

  local col = math.floor((vim.api.nvim_win_get_width(0) - width) / 2) - 1
  local row = math.floor((vim.api.nvim_win_get_height(0) - height) / 2) - 1

  local buf = vim.api.nvim_create_buf(false, true)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "single",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  return { buf = buf, win = win }
end

M.setup = function()
end

---@class presentation.Slides
---@field slides string[]: The slides of the file

--- Takes some lines and parses them
---@param lines string[]: The lines in the buffer
---@return presentation.Slides
local parse_slides = function(lines)
  local slides = { slides = {} }
  local current_slide = {}

  local separtor = "^#"

  for _, line in ipairs(lines) do
    -- print(line, "find:", line:find(separtor), "|")
    if line:find(separtor) then
      if #current_slide > 0 then
        table.insert(slides.slides, current_slide)
      end
      current_slide = {}
    end

    table.insert(current_slide, line)
  end
  table.insert(slides.slides, current_slide)

  return slides
end

-- TODO: floating window

M.start_presentation = function(opts)
  opts = opts or {}
  opts.bufnr = opts.bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(opts.bufnr, 0, -1, false)
  local parsed = parse_slides(lines)
  local float = create_floating_window()

  local current_slide = 1
  vim.keymap.set("n", "n", function()
    current_slide = math.min(current_slide + 1, #parsed.slides)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
  end, {
      buffer = float.buf
    })
  vim.keymap.set("n", "p", function()
    current_slide = math.max(current_slide - 1, 1)
    vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[current_slide])
  end, {
      buffer = float.buf
    })
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(float.win, true)
  end, {
      buffer = float.buf
    })

  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, parsed.slides[1])
end

M.start_presentation({ bufnr = 30 })

-- vim.print(parse_slides({
--   "# Hello",
--   "this is markdown",
--   "# World",
--   "this is nice",
-- }))

return M

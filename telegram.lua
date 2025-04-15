-- ебал отец

local config = {
  url = "http://localhost:5000",
  update_interval = 1,
  chat_id = nil,
  chat_name = nil,
  max_display = 5, -- Always show exactly 5 messages
  max_lines_per_message = 2 -- Limit message height to prevent overflow
}

-- сын шлюхи
local colors = {
  background = colors.black,
  header = colors.blue,
  headerText = colors.white,
  divider = colors.lightGray,
  message = colors.white,
  messageBackground = colors.black,
  input = colors.white,
  inputBackground = colors.gray,
  yourName = colors.yellow,
  otherName = colors.lime,
  error = colors.red,
  statusBar = colors.blue,
  statusText = colors.white,
  menuSelected = colors.lightBlue,
  menuText = colors.white,
  newMessage = colors.green
}

-- БЛЯТЬ ИДИ НАХУЙ Я МУЧАЛСЯ НАД ЭТИМ НЕСКОЛЬКО МИНУТ
local function centerText(text, width)
  local x = math.floor((width - #text) / 2) + 1
  return x
end

local function splitText(text, maxWidth)
  local lines = {}
  while #text > maxWidth do
    local breakPoint = maxWidth
    while breakPoint > 1 and text:sub(breakPoint, breakPoint) ~= " " do
      breakPoint = breakPoint - 1
    end
    
    if breakPoint == 1 then
      -- If no space found, force break at maxWidth
      table.insert(lines, text:sub(1, maxWidth))
      text = text:sub(maxWidth + 1)
    else
      table.insert(lines, text:sub(1, breakPoint))
      text = text:sub(breakPoint + 1)
    end
  end
  
  if #text > 0 then
    table.insert(lines, text)
  end
  
  return lines
end

-- бэкграунд
local function drawHeader(title)
  term.setBackgroundColor(colors.header)
  term.setTextColor(colors.headerText)
  
  local w, h = term.getSize()
  term.setCursorPos(1, 1)
  term.clearLine()
  
  local headerText = "Telegram - " .. title
  local x = centerText(headerText, w)
  term.setCursorPos(x, 1)
  write(headerText)
  
  term.setBackgroundColor(colors.divider)
  term.setCursorPos(1, 2)
  term.clearLine()
  
  term.setBackgroundColor(colors.background)
  term.setTextColor(colors.message)
end

local function drawStatusBar(status)
  local w, h = term.getSize()
  term.setCursorPos(1, h)
  term.setBackgroundColor(colors.statusBar)
  term.setTextColor(colors.statusText)
  term.clearLine()
  write(" " .. status)
  
  term.setBackgroundColor(colors.background)
  term.setTextColor(colors.message)
end

-- типо две строчки ввод но оно не работает сами почините
local function drawInputBar()
  local w, h = term.getSize()
  
  -- Верхняя строка области ввода (инструкция)
  term.setCursorPos(1, h - 2)
  term.setBackgroundColor(colors.inputBackground)
  term.setTextColor(colors.input)
  term.clearLine()
  term.write(" Type your message:")
  
  -- нижняя строка
  term.setCursorPos(1, h - 1)
  term.setBackgroundColor(colors.inputBackground)
  term.setTextColor(colors.input)
  term.clearLine()
  term.write(" > ")
  
  local input = read()
  term.setBackgroundColor(colors.background)
  return input
end

local function displayMessage(sender, text, isYou, isNew, y, maxY)
  local w, h = term.getSize()
  local maxWidth = w - 3  -- Leave space for margins
  
  -- а
  if y >= maxY then
    return y
  end
  
  term.setCursorPos(1, y)
  term.setBackgroundColor(colors.messageBackground)
  
  if isYou then
    term.setTextColor(colors.yourName)
    write("You: ")
  else
    term.setTextColor(isNew and colors.newMessage or colors.otherName)
    write(sender .. ": ")
  end
  
  term.setTextColor(colors.message)
  
  local nameLength = isYou and 5 or #sender + 2
  
  local lines = splitText(text, maxWidth)
  
  -- нет
  local displayLines = math.min(#lines, config.max_lines_per_message)
  
  -- Пиздец
  write(lines[1] or "")
  y = y + 1
  
  -- моя мать ебали 3 таджика
  for i = 2, displayLines do
    -- Проверяем границы
    if y >= maxY then
      break
    end
    
    term.setCursorPos(3, y)
    write(lines[i])
    y = y + 1
  end
  
  -- сообщение обрезано
  if #lines > displayLines and y < maxY then
    term.setCursorPos(3, y)
    write("...")
    y = y + 1
  end
  
  return y
end

local function drawMenu(options, selected)
  term.setBackgroundColor(colors.background)
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.headerText)
  local w, h = term.getSize()
  
  local title = "TELEGRAM FOR COMPUTERCRAFT"
  local x = centerText(title, w)
  term.setCursorPos(x, 3)
  write(title)
  
  term.setCursorPos(1, 5)
  term.setTextColor(colors.message)
  print("Choose connection method:")
  print()
  
  for i, option in ipairs(options) do
    if i == selected then
      term.setBackgroundColor(colors.menuSelected)
      term.setTextColor(colors.menuText)
    else
      term.setBackgroundColor(colors.background)
      term.setTextColor(colors.message)
    end
    
    local optText = "  " .. option .. "  "
    local optX = centerText(optText, w)
    term.setCursorPos(optX, 7 + (i-1)*2)
    write(optText)
  end
  
  term.setBackgroundColor(colors.background)
  term.setTextColor(colors.message)
  
  local instructions = "Use Arrow Keys to navigate, Enter to select"
  local instX = centerText(instructions, w)
  term.setCursorPos(instX, h-3)
  write(instructions)
end

-- апи
local function request(endpoint, method, data)
  local url = config.url .. endpoint
  local response
  
  if method == "GET" then
    response = http.get(url)
  else
    response = http.post(
      url, 
      textutils.serializeJSON(data or {}),
      {["Content-Type"] = "application/json"}
    )
  end
  
  if response then
    local content = response.readAll()
    response.close()
    
    local success, result = pcall(textutils.unserializeJSON, content)
    if success then
      return result
    else
      return nil, "Invalid JSON response"
    end
  end
  return nil, "Failed to connect to server"
end

local function findChatByUsername(username)
  return request("/find_chat/" .. username, "GET")
end

local function getMessages(last_id)
  return request("/messages/" .. config.chat_id .. "?last_id=" .. (last_id or 0), "GET")
end

local function sendMessage(text)
  return request("/send", "POST", {
    chat_id = config.chat_id,
    text = text
  })
end

-- меню
local function selectConnectionMethod()
  local options = {"Connect by Username", "Connect by Chat ID"}
  local selected = 1
  local chosen = false
  
  while not chosen do
    drawMenu(options, selected)
    
    local event, key = os.pullEvent("key")
    if key == keys.up and selected > 1 then
      selected = selected - 1
    elseif key == keys.down and selected < #options then
      selected = selected + 1
    elseif key == keys.enter then
      chosen = true
    end
  end
  
  return selected
end

local function connectByUsername()
  term.setBackgroundColor(colors.background)
  term.clear()
  term.setCursorPos(1, 3)
  term.setTextColor(colors.headerText)
  print("CONNECT BY USERNAME")
  print("")
  term.setTextColor(colors.message)
  print("Enter username/group to connect:")
  print("(ex: username or @username)")
  
  term.setTextColor(colors.input)
  write(" > ")
  local input = read()
  
  -- пиздец снова
  local username = input:gsub("^@", "")
  
  term.setTextColor(colors.message)
  print("Connecting to @" .. username .. "...")
  
  local chat, err = findChatByUsername(username)
  if not chat or not chat.id then
    term.setTextColor(colors.error)
    print("Error: " .. (err or "Chat not found"))
    print("Press any key to try again")
    os.pullEvent("key")
    return nil, nil
  end
  
  return chat.id, chat.name or username
end

local function connectByChatID()
  term.setBackgroundColor(colors.background)
  term.clear()
  term.setCursorPos(1, 3)
  term.setTextColor(colors.headerText)
  print("CONNECT BY CHAT ID")
  print("")
  term.setTextColor(colors.message)
  print("Enter the Chat ID:")
  
  term.setTextColor(colors.input)
  write(" > ")
  local input = read()
  
  local chatID = tonumber(input)
  if not chatID then
    term.setTextColor(colors.error)
    print("Error: Invalid chat ID (must be a number)")
    print("Press any key to try again")
    os.pullEvent("key")
    return nil, nil
  end
  
  term.setTextColor(colors.message)
  print("Enter a display name for this chat:")
  term.setTextColor(colors.input)
  write(" > ")
  local chatName = read()
  
  return chatID, chatName
end

-- 5 сообщений
local function chatInterface()
  local last_id = 0
  local w, h = term.getSize()
  local history = {}
  local newMessages = {}
  
  term.clear()
  
  -- это типо команды почините их
    local function handleCommand(cmd)
    if cmd == "/exit" then
      return true
    elseif cmd == "/clear" then
      history = {}
      last_id = 0
      newMessages = {}
    elseif cmd == "/help" then
      term.setBackgroundColor(colors.background)
      term.clear()
      term.setCursorPos(1, 1)
      term.setTextColor(colors.headerText)
      print("COMMANDS:")
      term.setTextColor(colors.message)
      print("/exit - Exit to menu")
      print("/clear - Clear message history")
      print("/help - Show this help")
      
      print("\nPress any key to return...")
      os.pullEvent("key")
      return false
    end
    return false
  end
  
  local function refreshDisplay()
    -- очистка
    term.setBackgroundColor(colors.background)
    term.clear()
    
    drawHeader(config.chat_name)
    
    -- область
    -- Header (2) + Two-line Input (2) + Status (1) = 5 lines reserved (спастил)
    local messageAreaEnd = h - 3 -- до двустрочного поля ввода
    
    -- типо
    -- ниггер
    local startIdx = math.max(1, #history - config.max_display + 1)
    local y = 3
    
    -- бля
    for i = #history, startIdx, -1 do
      local msg = history[i]
      local isNew = false
      
      -- почему так много комментариев
      for _, newMsg in ipairs(newMessages) do
        if newMsg.id == msg.id then
          isNew = true
          break
        end
      end
      
      y = displayMessage(msg.sender, msg.text, msg.isYou, isNew, y, messageAreaEnd)
      
      -- остановись
      if y >= messageAreaEnd then
        break
      end
    end
    
    -- мамут рахал
    term.setCursorPos(1, h - 2)
    term.setBackgroundColor(colors.inputBackground)
    term.setTextColor(colors.input)
    term.clearLine()
    term.write(" Type your message:")
    
    term.setCursorPos(1, h - 1)
    term.setBackgroundColor(colors.inputBackground)
    term.setTextColor(colors.input)
    term.clearLine()
    term.write(" > ")
    
    -- че
    drawStatusBar("Connected to " .. config.chat_name .. " | Messages: " .. #history)
  end
  
  -- че за
  local messages, err = getMessages(0)
  if messages and #messages > 0 then
    for _, msg in ipairs(messages) do
      table.insert(history, {
        id = msg.id,
        sender = msg.sender,
        text = msg.text,
        isYou = false
      })
      last_id = math.max(last_id, msg.id)
    end
    
    -- пяти сообщения
    while #history > config.max_display do
      table.remove(history, 1)
    end
  end
  
  -- перезагрузка дисплея типо луп
  while true do
    refreshDisplay()
    
    -- индикатор
    newMessages = {}
    
    local done = false
    parallel.waitForAny(
      -- инпут
      function()
        -- андрк гандон
        term.setCursorPos(4, h - 1)
        local input = read()
        
        if input and #input > 0 then
          -- Check if it's a command
          if input:sub(1, 1) == "/" then
            done = handleCommand(input)
          else
            local success, err = sendMessage(input)
            if success then
              local msgId = (success.message_id or #history + 1)
              
              -- сообщение в истории
              table.insert(history, {
                id = msgId,
                sender = "You",
                text = input,
                isYou = true
              })
              
              -- последние 5 сообщений
              while #history > config.max_display do
                table.remove(history, 1)
              end
            else
              drawStatusBar("Error sending message: " .. (err or "unknown error"))
              sleep(1)
            end
          end
          refreshDisplay()
        end
      end,
      
      -- поллинг
      function()
        while not done do
          sleep(config.update_interval)
          local messages, err = getMessages(last_id)
          
          if messages and #messages > 0 then
            for _, msg in ipairs(messages) do
              table.insert(history, {
                id = msg.id,
                sender = msg.sender,
                text = msg.text,
                isYou = false
              })
              table.insert(newMessages, {id = msg.id})
              last_id = math.max(last_id, msg.id)
            end
            
            -- ла ьятьми
            while #history > config.max_display do
              table.remove(history, 1)
            end
            
            refreshDisplay()
          elseif err then
            -- ошибка
            drawStatusBar("Connected to " .. config.chat_name)
          end
        end
      end
    )
    
    if done then break end
  end
end

-- сама прога
local function main()
  while true do
    local method = selectConnectionMethod()
    
    if method == 1 then
      config.chat_id, config.chat_name = connectByUsername()
    else
      config.chat_id, config.chat_name = connectByChatID()
    end
    
    if config.chat_id and config.chat_name then
      chatInterface()
    end
  end
end

-- ран проги
local ok, err = pcall(main)
if not ok then
  term.setBackgroundColor(colors.black)
  term.clear()
  term.setCursorPos(1, 1)
  term.setTextColor(colors.red)
  print("Error running Telegram client:")
  print(err)
  print("")
  term.setTextColor(colors.white)
  print("Press any key to exit")
  os.pullEvent("key")
end

  local client = Client.new()

  if client:connect('localhost', 8082) then
    local t = {}
    for i = 1, 5 do
      client:send('Message ' .. i)
    end
    client:close()
  end

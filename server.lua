local Client = require('network/client')
local socket = require('socket')

local function listen(self, port)
  self.__server = socket.bind('*', port)
  if not self.__server then
    return false
  end
  self.__server:settimeout(0)
  if self.onServerListening then
    self:onServerListening(port)
  end
  return true
end

local function accept(self)
  local client, err = self.__server:accept()
  if client then
    local connect = true
    if self.onClientConnect then
      connect = self:onClientConnect(client)
    end
    if connect then
      table.insert(self.__clients, Client.new(client))
    end
    return connect
  elseif err ~= 'timeout' then
    return false, err
  end
  return false
end

local function poll(self)
  local i = 1
  while i <= #self.__clients do
    local client = self.__clients[i]
    local success, data = client:receive()
    while success do
      if self.onClientMessage then
        self:onClientMessage(client, data)
      end
      success, data = client:receive()
    end
    if not data then
      i = i + 1
    else
      if data ~= 'closed' and self.onClientError then
        self:onClientError(client, data)
      end
      if self.onClientDisconnect then
        self:onClientDisconnect(client, data)
      end
      table.remove(self.__clients, i)
    end
  end
end

local function kick(self, client)
  for i=1, #self.__clients do
    if self.__clients[i] == client then
      if self.onClientDisconnect then
        self:onClientDisconnect(client, 'kicked')
      end
      table.remove(self.__clients, i)
      return true
    end
  end
  return false
end

local function run(self)
  local success, err = self:accept()
  while success do
    success, err = self:accept()
  end
  if err then
    return false, err
  end
  self:poll()
end

local function new()
  return {
    __clients = {},
    listen = listen,
    accept = accept,
    kick = kick,
    run = run,
    poll = poll,
  }
end

return {
  new = new
}
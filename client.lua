local bit = require('bit')
local socket = require('socket')

local function connect(self, host, port)
  local socket, err = socket.connect(host, port)
  if not socket then
    return false, err
  end
  self.__socket = socket
  self.__socketInfo = { self.__socket:getsockname() }
  self.__socket:settimeout(0)
  self.__open = true
  return true
end

local function close(self)
  if self.__open then
    self.__socket:close()
    self.__open = false
  end
end

local function receive(self)
  local data, err, part = self.__socket:receive(4096)
  local finalData = data or part
  if finalData and #finalData > 0 then
    self.__bufferSize = self.__bufferSize + #finalData
    table.insert(self.__buffer, finalData)
  end

  if self.__bufferSize > 4 then
    if #self.__buffer[1] <= 4 then
      self.__buffer = { table.concat(self.__buffer) }
    end
    local headBytes = { self.__buffer[1]:byte(1, 4) }
    local size = bit.bor(bit.lshift(headBytes[1], 24), bit.lshift(headBytes[2], 16), bit.lshift(headBytes[3], 8), headBytes[4])
    if size <= self.__bufferSize then
      if #self.__buffer[1] < size then
        self.__buffer = { table.concat(self.__buffer) }
      end
      local data = self.__buffer[1]:sub(5, size+5)
      self.__buffer[1] = self.__buffer[1]:sub(size+5)
      self.__bufferSize = self.__bufferSize - (size + 4)
      return true, data
    end
  end

  if err ~= 'timeout' then
    self.__open = false
    return false, err
  end
  
  return false, nil
end

local function send(self, data)
  if self.__open then
    local data = tostring(data)
    local size = #data
    local headBytes = {
      bit.band(bit.rshift(size, 24), 255),
      bit.band(bit.rshift(size, 16), 255),
      bit.band(bit.rshift(size, 8), 255),
      bit.band(size, 255)
    }
    local head = string.char(headBytes[1], headBytes[2], headBytes[3], headBytes[4])
    local fullData = head .. data
    local parts = {}
    local lenSent = 0
    while lenSent < #fullData do
      local len, err = self.__socket:send(fullData:sub(lenSent+1, math.min(lenSent+1+4096, #fullData)))
      lenSent = lenSent + len
      if err then
        if err == 'close' then
          self.__open = false
        end
        return 0, err
      end
    end
    return size, nil
  end
  return 0, nil
end

local function isOpen(self)
  return self.__open
end

local function getsockname(self)
  return table.unpack(self.__socketInfo)
end

local function getIP(self)
  return self.__socketInfo[1]
end

local function getPort(self)
  return self.__socketInfo[2]
end

local function new(socket)
  if socket then
    socket:settimeout(0)
  end
  return {
    __socket = socket,
    __buffer = {},
    __bufferSize = 0,
    __open = socket ~= nil,
    __socketInfo = socket and { socket:getsockname() } or {},
    close = close,
    connect = connect,
    isOpen = isOpen,
    receive = receive,
    send = send,
    getsockname = getsockname,
    getIP = getIP,
    getPort = getPort,
  }
end

return {
  new = new,
}

local Server = require('server')

local server = Server.new()

function server.onServerListening(self, port)
  print('Server listening on port ' .. port)
end

function server.onClientConnect(self, client)
  print('Client connected: ', client:getIP())
  -- Return true to accept connection, otherwise reject it
  return true
end

function server.onClientDisconnect(self, client, reason)
  print('Client disconnected: ', client:getIP(), reason)
end

function server.onClientMessage(self, client, message)
  print(client, message)
end

server:listen(port)

-- Loop until there is an error or the server is closed
-- server:run() accepts new connections and buffers messages from clients
while server:run() do
  
end

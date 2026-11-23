const http = require('node:http');
const { randomUUID } = require('node:crypto');
const { WebSocketServer, WebSocket } = require('ws');

const port = Number(process.env.PORT || 8080);
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ name: 'Neon Velocity Race Server', status: 'online', waiting: queue.length }));
});
const wss = new WebSocketServer({ server });
const queue = new Set();

function send(socket, payload) {
  if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify(payload));
}
function removeFromQueue(socket) { queue.delete(socket); }
function leaveRoom(socket) {
  removeFromQueue(socket);
  const opponent = socket.opponent;
  if (opponent) {
    opponent.opponent = null;
    opponent.roomId = null;
    send(opponent, { type: 'opponent_left' });
  }
  socket.opponent = null;
  socket.roomId = null;
}
function matchPlayers(first, second) {
  const roomId = randomUUID();
  first.roomId = roomId;
  second.roomId = roomId;
  first.opponent = second;
  second.opponent = first;
  send(first, { type: 'matched', roomId, playerId: 'A', opponentName: second.playerName });
  send(second, { type: 'matched', roomId, playerId: 'B', opponentName: first.playerName });
}
wss.on('connection', (socket) => {
  socket.playerName = 'Driver';
  socket.on('message', (raw) => {
    let message;
    try { message = JSON.parse(raw.toString()); } catch { return; }
    if (message.type === 'join') {
      socket.playerName = String(message.name || 'Driver').slice(0, 18);
      const waiting = [...queue].find((candidate) => candidate.readyState === WebSocket.OPEN && candidate !== socket);
      if (waiting) {
        removeFromQueue(waiting);
        matchPlayers(waiting, socket);
      } else {
        queue.add(socket);
        send(socket, { type: 'waiting' });
      }
    } else if (message.type === 'state' && socket.opponent) {
      send(socket.opponent, {
        type: 'state',
        progress: Math.max(0, Math.min(1, Number(message.progress) || 0)),
        lane: Math.max(-1, Math.min(1, Number(message.lane) || 0)),
        speed: Math.max(0, Number(message.speed) || 0),
      });
    } else if (message.type === 'finish' && socket.opponent) {
      send(socket.opponent, { type: 'opponent_finished' });
    } else if (message.type === 'leave') {
      leaveRoom(socket);
    }
  });
  socket.on('close', () => leaveRoom(socket));
  socket.on('error', () => leaveRoom(socket));
});
server.listen(port, '0.0.0.0', () => console.log('Race server listening on ' + port));

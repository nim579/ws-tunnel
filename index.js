var Client = require('./lib/client');
var Server = require('./lib/server');

Tunnel = Client;
Tunnel.Server = Server;

module.exports = Tunnel;

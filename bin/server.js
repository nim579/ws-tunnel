#!/usr/bin/env node

var pkg     = require('../package.json');
var program = require('commander');
var Server  = require('../lib/server');

program
	.version(pkg.version)
    .option('-H, --host [host]', 'Host of tunnel', '0.0.0.0')
    .option('-P, --port [number]', 'Port of tunnel', 4488)
    .option('-h, --server-host [host]', 'Host of listener server', '0.0.0.0')
    .option('-p, --server-port [number]', 'Port of listener server', 4480)
    .option('-m, --mask [number]', 'RegExp mask for searching tunnel name in server host', null)
    .option('-t, --timeout [time]', 'Connection and request timeout', 5000)
    .parse(process.argv);

var options = {};
if(program.host)       options.host           = program.host;
if(program.port)       options.port           = program.port;
if(program.serverHost) options.listenerHost   = program.serverHost;
if(program.serverPort) options.listenerPort   = program.serverPort;
if(program.mask)       options.mask           = program.mask;
if(program.timeout)    options.connectTimeout = program.timeout;

new Server(options);

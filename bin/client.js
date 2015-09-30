#!/usr/bin/env node

var pkg     = require('../package.json');
var program = require('commander');
var Client  = require('../lib/client');

program
    .version(pkg.version)
    .option('-n, --name [name]', 'Name of tunnel', null)
    .option('-h, --localhost [url]', 'Host for tunneling', null)
    .option('-t, --tunnel [url]', 'Socket URL of tunnel', null)
    .option('-r, --reconnect [time]', 'Time for reconnection', null)
    .parse(process.argv);

var options = {};
if(program.localhost) options.localHostname    = program.localhost;
if(program.tunnel)    options.host             = program.tunnel;
if(program.name)      options.name             = program.name;
if(program.reconnect) options.reconnectTimeout = program.reconnect;

new Client(options);

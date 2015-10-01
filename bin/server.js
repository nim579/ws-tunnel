#!/usr/bin/env node

var _       = require('underscore');
var fs      = require('fs');
var pkg     = require('../package.json');
var path    = require('path');
var program = require('commander');
var Server  = require('../lib/server');

var presetPath = path.join(path.dirname(process.mainModule.filename), '../server-preset.json');
var preset = {}
try {
    var file = fs.readFileSync(presetPath);
    preset = JSON.parse(file);
} catch (e){}

program
    .version(pkg.version)
    .option('-H, --host [host]', 'Host of tunnel')
    .option('-P, --port [number]', 'Port of tunnel')
    .option('-h, --server-host [host]', 'Host of listener server')
    .option('-p, --server-port [number]', 'Port of listener server')
    .option('-m, --mask [number]', 'RegExp mask for searching tunnel name in server host')
    .option('-t, --timeout [time]', 'Connection and request timeout')
    .option('-s, --save', 'Save current options as preset', false)
    .parse(process.argv);

program = _.extend(preset, program);

if(program.save){
    saveData = {
        host: program.host,
        port: program.port,
        serverHost: program.serverHost,
        serverPort: program.serverPort,
        mask: program.mask,
        timeout: program.timeout
    }
    fs.writeFileSync(presetPath, JSON.stringify(saveData));
}

var options = {};
if(program.host)       options.host           = program.host;
if(program.port)       options.port           = program.port;
if(program.serverHost) options.listenerHost   = program.serverHost;
if(program.serverPort) options.listenerPort   = program.serverPort;
if(program.mask)       options.mask           = program.mask;
if(program.timeout)    options.connectTimeout = program.timeout;

new Server(options);

#!/usr/bin/env node

var _       = require('underscore');
var fs      = require('fs');
var pkg     = require('../package.json');
var path    = require('path');
var program = require('commander');
var Client  = require('../lib/client');

var presetPath = path.join(path.dirname(process.mainModule.filename), '../client-preset.json');
var preset = {};
try {
    var file = fs.readFileSync(presetPath);
    preset = JSON.parse(file);
} catch (e){}
console.log(process.mainModule.filename)

program
    .version(pkg.version)
    .option('-n, --name [name]', 'Name of tunnel')
    .option('-h, --localhost [url]', 'Host for tunneling')
    .option('-t, --tunnel [url]', 'Socket URL of tunnel')
    .option('-r, --reconnect [time]', 'Time for reconnection')
    .option('-s, --save', 'Save current options as preset', false)
    .parse(process.argv);

program = _.extend(preset, program);

if(program.save){
    saveData = {
        localhost: program.localhost,
        tunnel: program.tunnel,
        name: program.name,
        reconnect: program.reconnect
    }
    fs.writeFileSync(presetPath, JSON.stringify(saveData));
}

var options = {};
if(program.localhost) options.localHostname    = program.localhost;
if(program.tunnel)    options.host             = program.tunnel;
if(program.name)      options.name             = program.name;
if(program.reconnect) options.reconnectTimeout = program.reconnect;

new Client(options);

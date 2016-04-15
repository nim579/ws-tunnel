events = require 'events'
http   = require 'http'
url    = require 'url'
WS     = require('ws').Server
_      = require 'underscore'


class Server
    options:
        host: '0.0.0.0'
        port: 4488
        listenerHost: '0.0.0.0'
        listenerPort: 4480
        mask: '(\\w+)\\.'
        connectTimeout: 5000

    constructor: (options={})->
        _.extend @, new events.EventEmitter()
        @options = _.extend {}, @options, options

        @tunnels = []

        @startListener()
        @startServer()

    startServer: ->
        @_server = new WS port: @options.port, host: @options.host
        @_server.on 'connection', _.bind @connection, @

    startListener: ->
        @_listener = http.createServer (request, response)=>
            @listenerRequest request, response

        @_listener.listen Number(@options.listenerPort), @options.listenerHost

    generateId: ->
        return _.uniqueId new Date().getTime() + "_"

    connection: (connection)->
        timeout = setTimeout =>
            connection.close()
        , @options.connectTimeout

        onMessage = (message)=>
            data = {}
            try
                data = JSON.parse message

            clearTimeout timeout
            connection.removeListener 'message', onMessage

            if data.method is 'connect' and data.params and data.params.name
                if @getTunnelByName data.params.name
                    @responseTunnel connection, data.id, data.method, null, code: 'name_already_exists'
                    connection.close()
                    console.log 'Connection refused. Tunnel name already exists'

                else
                    @setTunnel connection, data
                    @responseTunnel connection, data.id, data.method, {}

            else
                @responseTunnel connection, data.id, data.method, null, code: 'no_connection'
                connection.close()

        connection.on 'message', onMessage

    setTunnel: (connection, data)->
        tunnel =
            name: data.params.name
            connection: connection

        onMessage = (message)=>
            @message connection, message

        connection.on 'close', =>
            connection.removeAllListeners()
            @tunnels = _.without @tunnels, tunnel
            console.log "disconnected: #{tunnel.name}"

        connection.on 'message', onMessage

        @tunnels.push tunnel
        console.log "connected: #{tunnel.name}"

    message: (connection, message)->
        data = {}
        try
            data = JSON.parse message

        if data.id?
            @emit "message.#{data.id}", data

        @emit 'message', data

    listenerRequest: (req, res)->
        host = req.headers.host
        if host
            hostname = url.parse('tunn://'+host).hostname
            namePart = hostname.match new RegExp @options.mask

            tunnelName = null
            tunnelName = namePart[1] if namePart

            if tunnelName and tunnel = @getTunnelByName tunnelName
                @requestTunnel tunnel.connection, tunnelName, req.url, req.headers, res

            else
                @tunnelNotFound res

    listenerResponse: (res, err, data)->
        if err
            body = '404 Not Found'
            bodyType = null
            if err.body
                body = new Buffer(err.body)
                bodyType = 'binary'

            res.writeHead err.code or 404, err.headers or {}
            res.write body, if bodyType then bodyType
            res.end()

        else
            body = '200 OK'
            bodyType = null
            if data.body
                body = new Buffer(data.body)
                bodyType = 'binary'

            res.writeHead data.code or 200, data.headers or {}
            res.write body, if bodyType then bodyType
            res.end()

    tunnelNotFound: (res)->
        res.writeHead 406
        res.write "406 Not Acceptable"
        res.end()

    getTunnelByName: (name)->
        return _.findWhere @tunnels, name: name

    requestTunnel: (connection, tunnelName, url, headers, res)->
        id = @generateId()
        startTime = new Date()

        connection.send JSON.stringify
            id: id
            method: 'request'
            params:
                url: url
                headers: headers or {}

        @once "message.#{id}", (data)=>
            @listenerResponse res, data.error, data.result
            console.log "[#{new Date().toJSON()}] (+#{new Date() - startTime}ms) #{tunnelName}: #{url}"

    responseTunnel: (connection, id, method, result, error=null)->
        connection.send JSON.stringify
            id: if id then id
            method: method,
            result: result
            error: error


module.exports = Server

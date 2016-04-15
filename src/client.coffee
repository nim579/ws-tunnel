request = require 'request'
events  = require 'events'
url     = require 'url'
WS      = require 'ws'
_       = require 'underscore'


class Client
    options:
        localHostname: 'http://localhost:4000'
        host: 'localhost:4488'
        name: 'local'
        reconnectTimeout: 5000

    constructor: (options)->
        _.extend @, new events.EventEmitter()
        @options = _.extend {}, @options, options

        @openTunnel()
        @bindExit()

    openTunnel: ->
        host = @options.host

        unless @options.host.match(/^(ws|wss):\/\//i)
            host = "ws://" + @options.host.replace(/^(\w+):\/\//i, '').replace(/^\/\//, '')

        @_tunnel = new WS host

        @_tunnel.on 'open', =>
            console.log 'Connected'
            @sendConnect()
            @listenRequests()

        @_tunnel.on 'close', =>
            @recopenTunnel()

    stop: ->
        @_tunnel?.close()
        console.log 'Connection closed!'

    recopenTunnel: ->
        console.log 'Connection closed'

        setTimeout =>
            console.log 'Reconnection...'
            @openTunnel()
        , @options.reconnectTimeout

    bindExit: ->
        exit = =>
            process.removeAllListeners 'SIGINT'
            process.removeAllListeners 'SIGTERM'
            @stop()

            console.log 'Stop process'
            process.exit()

        process.on 'SIGINT', exit
        process.on 'SIGTERM', exit

    generateId: ->
        return _.uniqueId new Date().getTime() + "_"

    sendConnect: ->
        @_tunnel.send JSON.stringify
            id: @generateId()
            method: 'connect'
            params:
                name: @options.name

    listenRequests: ->
        @_tunnel.on 'message', (message)=>
            data = {}
            try
                data = JSON.parse message

            if data.id? and data.method is 'request'
                @request data

            if data.error
                console.log 'Error:', JSON.stringify data.error

                if data.method is 'connect' and data.error.code is 'name_already_exists'
                    console.log 'Name already exists! Change another name and restart.'
                    @stop()
                    process.exit()

    request: (req)->
        if req.params and req.params.url
            reqUrl = url.parse req.params.url
            addr = url.resolve @options.localHostname, reqUrl.path
            headers = if req.params.headers then req.params.headers else {}

            console.log addr
            request {url: addr, encoding: null, headers: headers}, (err, response, body)=>
                if err
                    console.log err
                    @response req,
                        code: 500
                        body: '500 Internal Server Error'

                else
                    @response req, null,
                        code: response.statusCode
                        headers: response.headers
                        body: body.toJSON().data

    response: (req, err=null, result)->
        @_tunnel.send JSON.stringify
            id: req.id
            method: req.method
            result: if result then result else null
            error: err


module.exports = Client

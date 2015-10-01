request = require 'request'
events  = require 'events'
url     = require 'url'
WS      = require 'ws'
_       = require 'underscore'


class Client
    options:
        localHostname: 'http://localhost:4000'
        host: 'ws://localhost:4488'
        name: 'local'
        reconnectTimeout: 5000

    constructor: (options)->
        _.extend @, new events.EventEmitter()
        @options = _.extend {}, @options, options

        @openTunnel()

    openTunnel: ->
        @_tunnel = new WS @options.host

        @_tunnel.on 'open', =>
            console.log 'Connected'
            @sendConnect()
            @listenRequests()

        @_tunnel.on 'close', =>
            @recopenTunnel()

    recopenTunnel: ->
        console.log 'Connection closed'

        setTimeout =>
            console.log 'Reconnection...'
            @openTunnel()
        , @options.reconnectTimeout

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

    request: (req)->
        if req.params and req.params.url
            reqUrl = url.parse req.params.url
            addr = url.resolve @options.localHostname, reqUrl.path

            console.log addr
            request {url: addr, encoding: null}, (err, response, body)=>
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

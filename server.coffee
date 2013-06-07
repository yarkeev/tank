fs = require 'fs'

class TankServer

	port: 8888

	sessions: {}

	constructor: ->
		app = require('http').createServer @onHttpConnect
		@io = require('socket.io').listen app
		app.listen @port

		@_bindEvents()

	_bindEvents: ->
		@io.sockets.on 'connection', (socket) ->
			sessionId = new Date().getTime()
			socket.emit 'init', 
				sessionId: sessionId

			socket.on 'tank.move', (data) ->
				console.log data

	onHttpConnect: (req, res) ->
		fs.readFile "#{__dirname}/index.html", (err, data) ->
			if err
				res.writeHead 500
				res.end 'Error loading index.html'
			else
				res.writeHead 200
				res.end data

new TankServer()
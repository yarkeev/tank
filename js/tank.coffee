((window, $) ->
	'use strict'

	DEAFAULT_SPEED = 5

	DEAFAULT_BULLET_SPEED = 300

	DEAFAULT_BULLET_LENGTH = 400

	DEFAULT_TANK_WIDTH = 75

	DEFAULT_TANK_HEIGHT = 150

	DEFAULT_BULLET_WIDTH = 16

	DEFAULT_BULLET_HEIGHT = 16

	DEFAULT_BULLET_EXPLODE_TIME = 500

	DEFAULT_ANGLE_UPDATE_DELAY = 100

	DEBUG = true

	DOM_CONTAINER = null

	CLASSES = 
		tank:
			main: 'b-tank'
		bullet:
			main: 'b-bullet'

	###
	# Base class for all tank classes
	###
	class Base

		###
		# flag of enable debug
		# @var {boolean}
		###
		@debug: DEBUG

		###
		# log message in console
		# @param {string} message
		###
		log: (message) ->
			window.console.log message if @constructor.debug && window.console && window.console.log

		###
		# log error message in console
		# @param {string} message
		###
		error: (message) ->
			window.console.error message if @constructor.debug && window.console && window.console.log


	###
	# Pattern observer for event model
	###
	class Observer extends Base

		###
		# @constructor
		###
		constructor: ->
			super
			@_subscribers = {}

		###
		# subscribe
		# @param {string} id event identifier
		# @param {function} callback
		###
		on: (id, callback) ->
			id = $.trim id
			if id.length == 0
				@error 'incorrect id in Observer.on'
				@ 
			if !$.isFunction callback
				@error 'incorrect callback in Observer.on'
				@
			if @_subscribers[id]
				@_subscribers[id].push callback
			else
				@_subscribers[id] = [callback]
			@

		###
		# unsubscribe
		# @param {string} id event identifier
		# @param {function} callback
		###
		off: (id, callback) ->
			id = $.trim id
			if id.length == 0
				@error 'incorrect id in Observer.off'
				@
			if !$.isFunction callback
				@_subscribers[id] = []
			else
				handlers = @_subscribers[id]
				for handler, key in handlers
					console.log handler
					if handler == callback
						handlers[key] = null
			@

		###
		# call subscribed callbacks
		# @param {string} id event identifier
		###
		publish: (id) ->
			id = $.trim id
			if id.length == 0
				@error 'incorrect id in Observer.publish'
			handlers = @_subscribers[id]
			args = Array.prototype.slice.call arguments, 1 
			for key, handler of handlers
				handler?.apply @, args
			@

	###
	# Model of tank
	###
	class TankModel extends Observer

		###
		# available values of property direction
		# @param {array}
		###
		availableDirections: ['top', 'right', 'bottom', 'left']

		###
		# @constructor
		###
		constructor: ->
			super

			###
			# Current directrion
			# @var {string}
			###
			@_directrion = null

			###
			# Speed of tank in pixel per iteration
			# @var {number}
			###
			@_speed = DEAFAULT_SPEED

			###
			# width
			# @var {number}
			###
			@width = DEFAULT_TANK_WIDTH


			###
			# height
			# @var {number}
			###
			@height = DEFAULT_TANK_HEIGHT

			###
			# angle tank rotate
			# @var {number}
			###
			@_angle = 0

			###
			# last time of update angle
			# @var {number}
			###
			@_lastUpdateAngle = (new Date()).getTime()

			###
			# delay of skip rotate
			# @var {number}
			###
			@_angleUpdateDelay = DEFAULT_ANGLE_UPDATE_DELAY

		###
		# Set direction of tank
		# @param {string} direction
		###
		setDirection: (direction) ->
			if @availableDirections.indexOf(direction) != -1
				@_directrion = direction
				clearTimeout @_angleUpdateTimer
				@_angleUpdateTimer = setTimeout @_updateAngle.bind(@), @_angleUpdateDelay
				@publish 'changeDirection', direction
			else
				@error "unsupport direction #{direction}"

		###
		# return direction of tank
		# @return {string}
		###
		getDirection: ->
			angle = @getAngle() % 360

			switch angle
				when 0
					'top'
				when 90, -270
					'right'
				when 180, -180
					'bottom'
				when 270, -90
					'left'


		###
		# Set speed of tank
		# @param {number} speed on pixels per iteration
		###
		setSpeed: (speed) ->
			if !$.isNumeric speed
				@error 'incorrect speed in TankModel.setSpeed'
				@
			@_speed = speed

		###
		# return speed of tank
		# return {number}
		###
		getSpeed: ->
			@_speed

		###
		# return angle tank rotate
		# @return {number}
		###
		getAngle: ->
			@_angle

		###
		# update angle rotate
		###
		_updateAngle: ->
			if @_directrion == 'left'
				@_angle -= 90
			if @_directrion == 'right'
				@_angle += 90
			@publish 'angleChange', @_angle

	###
	# class of view
	###
	class View extends Observer

		###
		# @constructor
		###
		constructor: ->
			super
			@_$domContainer = DOM_CONTAINER

	###
	# model of bullet
	###
	class BulletModel extends Observer

		constructor: ->
			super

			@_speed = DEAFAULT_BULLET_SPEED
			@_length = DEAFAULT_BULLET_LENGTH
			@width = DEFAULT_BULLET_WIDTH
			@height = DEFAULT_BULLET_HEIGHT

		###
		# return speed of bullet
		# @return {number}
		###
		getSpeed: ->
			return @_speed

		###
		# return length of bullet
		# return {number}
		###
		getLength: ->
			return @_length

	###
	# View of bullet
	###
	class BulletView extends View

		###
		# @constructor
		# @param {number} coord.left X coordinate of tank
		# @param {number} coord.top Y coordinate of tank
		# @param {BulletModel} model model of ballet
		# @param {TankModel} tankModel model of tank 
		###
		constructor: (coord, model, tankModel) ->
			super
			@model = model
			@tankModel = tankModel
			@_explodeTime = DEFAULT_BULLET_EXPLODE_TIME
			@$bullet = $("<div class='#{CLASSES.bullet.main}'></div>").appendTo @_$domContainer
			@setCoord coord, @tankModel.getDirection()
			@move @tankModel.getDirection()

		###
		# set start coordinate
		# @param {number} coord.left X coordinate of tank
		# @param {number} coord.top Y coordinate of tank
		# @param {string} direction current tank direction
		###
		setCoord: (coord, direction) ->
			switch direction
				when 'left'
					coord.top -= (@tankModel.width / 2 + @model.height / 2)
				when 'right'
					coord.top -= (@tankModel.width / 2 + @model.height / 2)
					coord.left += @tankModel.height
				when 'top'
					coord.left += (@tankModel.width / 2 - @model.width / 2)
					coord.top -= @tankModel.height / 2
				when 'bottom'
					coord.left += (@tankModel.width / 2 - @model.width / 2)
					coord.top += (@tankModel.height / 2 - @model.height / 2)

			@$bullet.css coord

		###
		# move bullet
		# @param {string} direction
		###
		move: (direction) ->
			switch direction
				when 'left'
					@$bullet.animate
						left: "-=#{@model.getLength()}"
					, @model.getSpeed(), 'linear', @explode.bind @
				when 'right'
					@$bullet.animate
						left: "+=#{@model.getLength()}"
					, @model.getSpeed(), 'linear', @explode.bind @
				when 'top'
					@$bullet.animate
						top: "-=#{@model.getLength()}"
					, @model.getSpeed(), 'linear', @explode.bind @
				when 'bottom'
					@$bullet.animate
						top: "+=#{@model.getLength()}"
					, @model.getSpeed(), 'linear', @explode.bind @

		###
		# explode
		###
		explode: ->
			@$bullet.addClass 'explode'
			setTimeout () =>
				@$bullet.remove()
			, @_explodeTime

	###
	# View of tank
	###
	class TankView extends View

		keyMap:
			left: 37
			right: 39
			top: 38
			bottom: 40
			space: 32

		###
		# @constructor
		# @param {TankModel} model of tank
		###
		constructor: (model) ->
			super
			
			if !model || !(model instanceof TankModel)
				@error 'incorrect model in TankView.constructor'
				@

			@model = model
			@$tank = $("<div class='#{CLASSES.tank.main}'></div>").appendTo @_$domContainer
			@$tank.css @$tank.position()
			@_pressed = {}
			@_bindEvents()

			setInterval @update.bind(@), 10

		###
		# move tank
		# @param {string} directionX
		###
		move: (directionX) ->
			speed = @model.getSpeed()
			directionY = @model.getDirection()
			position = {}
			if directionX == 'forward'
				sign = 1
			if directionX == 'back'
				sign = -1

			switch directionY
				when 'top'
					position.top = parseInt(@$tank.css 'top') - sign * speed
				when 'right'
					position.left = parseInt(@$tank.css 'left') + sign * speed
				when 'bottom'
					position.top = parseInt(@$tank.css 'top') + sign * speed
				when 'left'
					position.left = parseInt(@$tank.css 'left') - sign * speed

			@$tank.css position

		###
		# shot (create bullet)
		###
		shot: ->
			bulletModel = new BulletModel
			bulletView = new BulletView @$tank.position(), bulletModel, @model

		###
		# rotate tank
		# @param {number} angle
		###
		rotate: (angle) ->
			@$tank.css
				'-webkit-transform': "rotate(#{angle}deg)"

		###
		# update view
		###
		update: ->
			for keyCode, value of @_pressed
				switch Number(keyCode)
					when @keyMap.left
						console.log 'left'
						@publish 'leftKeyDown', event
					when @keyMap.right
						console.log 'right'
						@publish 'rightKeyDown', event
					when @keyMap.top
						console.log 'top'
						@move 'forward'
						@publish 'topKeyDown', event
					when @keyMap.bottom
						console.log 'bottom'
						@move 'back'
						@publish 'bottomKeyDown', event
					when @keyMap.space
						@shot()
						delete @_pressed[@keyMap.space]

		###
		# bind dom events
		###
		_bindEvents: ->
			@_$domContainer.on 'keydown', (event) =>
				@_onKeyDown event
				event.preventDefault()

			@_$domContainer.on 'keyup', (event) =>
				@_onKeyUp event
				event.preventDefault()

		###
		# key down handler
		# @param {jQuery.Event} event jquery event object
		###
		_onKeyDown: (event) ->
			@_pressed[event.keyCode] = true

		###
		# key up handler
		# @param {jQuery.Event} event jquery event object
		###
		_onKeyUp: (event) ->
			delete @_pressed[event.keyCode]

	###
	# class of tank
	###
	class Tank extends Observer

		###
		# @constructor
		###
		constructor: ->
			super

			@model = new TankModel()
			@view = new TankView @model

			@_bindEvents()

		###
		# subscribe on view and model events
		###
		_bindEvents: ->
			@view.on 'leftKeyDown', (event) =>
				@model.setDirection 'left'
			@view.on 'rightKeyDown', (event) =>
				@model.setDirection 'right'

			@model.on 'angleChange', (angle) =>
				@view.rotate angle


	$ () ->
		DOM_CONTAINER = $(document.body) 
		new Tank()

) window, jQuery
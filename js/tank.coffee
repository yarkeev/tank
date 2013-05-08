((window, $) ->
	'use strict'

	DEFAULT_SPEED = 5

	DEFAULT_ANGLE_SPEED = 2

	DEFAULT_BULLET_SPEED = 300

	DEFAULT_BULLET_LENGTH = 250

	DEFAULT_BULLET_LENGTH_RANDOM = 100

	DEFAULT_BULLET_COORD_RANDOM = 50

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
	# function loop for animations 
	###
	requestAnimFrame = (() ->
		return window.requestAnimationFrame		||
			window.webkitRequestAnimationFrame	||
			window.mozRequestAnimationFrame		||
			window.oRequestAnimationFrame		||
			window.msRequestAnimationFrame		||
			(callback, element) ->
				window.setTimeout callback, (1000 / 60)
	)()

	`
	if (!Function.prototype.bind) {
		Function.prototype.bind = function (oThis) {
			if (typeof this !== "function") {
				// closest thing possible to the ECMAScript 5 internal IsCallable function
				throw new TypeError("Function.prototype.bind - what is trying to be bound is not callable");
			}

			var aArgs = Array.prototype.slice.call(arguments, 1), 
				fToBind = this, 
				fNOP = function () {},
				fBound = function () {
					return fToBind.apply(this instanceof fNOP && oThis
							? this
							: oThis,
							aArgs.concat(Array.prototype.slice.call(arguments)));
				};

			fNOP.prototype = this.prototype;
			fBound.prototype = new fNOP();

			return fBound;
		};
	}
	`

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
				if handlers.hasOwnProperty key
					handler?.apply @, args
			@

	###
	# Model of tank
	###
	class TankModel extends Observer

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
			@_speed = DEFAULT_SPEED

			###
			# Angle speed of tank in degrees per iteration
			# @var {number}
			###
			@_angleSpeed = DEFAULT_ANGLE_SPEED

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
			# delay of skip rotate
			# @var {number}
			###
			@_angleUpdateDelay = DEFAULT_ANGLE_UPDATE_DELAY

		###
		# Set direction of tank
		# @param {string} direction
		###
		rotate: (direction) ->
			if direction == 'left'
				@_angle -= @_angleSpeed
			else if direction == 'right'
				@_angle += @_angleSpeed
			@publish 'angleChange', @_angle


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
			(@_angle + 90) * Math.PI / 180

		###
		# update angle rotate
		###
		_updateAngle: ->
			###
			if @_directrion == 'left'
				@_angle -= 90
			if @_directrion == 'right'
				@_angle += 90
			@publish 'angleChange', @_angle
			###

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

			@_speed = DEFAULT_BULLET_SPEED
			@_length = DEFAULT_BULLET_LENGTH
			@_randomLength = DEFAULT_BULLET_LENGTH_RANDOM
			@_randomCoord = DEFAULT_BULLET_COORD_RANDOM
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
			@_length + Math.random() * @_randomLength

		###
		# return random coord
		# return {number}
		###
		getRandomCoord: ->
			@_randomCoord

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
			@setCoord coord
			@move @tankModel.getAngle()

		###
		# set start coordinate
		# @param {number} coord.left X coordinate of tank
		# @param {number} coord.top Y coordinate of tank
		# @param {string} direction current tank direction
		###
		setCoord: (coord, direction) ->
			angle = @tankModel.getAngle()
			width = @tankModel.width
			height = @tankModel.height

			@position =
				left: coord.left + (width / 2) + (height / 2) * Math.cos(angle + Math.PI)
				top: coord.top + (height / 2) * Math.sin(angle + Math.PI)
			@$bullet.css @position

		###
		# move bullet
		# @param {number} angle
		###
		move: (angle) ->
			length = @model.getLength()
			randomCoord = @model.getRandomCoord()
			@position = 
				left: @position.left + length * Math.cos(angle + Math.PI) + (Math.random() * randomCoord)
				top: @position.top + length * Math.sin(angle + Math.PI) + (Math.random() * randomCoord)
			@$bullet.animate @position, @model.getSpeed(), 'linear', () =>
				@explode()

		###
		# explode
		###
		explode: ->
			@$bullet.addClass 'explode'
			setTimeout () =>
				@$bullet.addClass 'hole'
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
			@position = @$tank.position()
			@lastShotTime = (new Date()).getTime()
			@_pressed = {}
			@_bindEvents()

			@update()

		###
		# move tank
		# @param {string} directionX
		###
		move: (direction) ->
			speed = @model.getSpeed()
			angle = @model.getAngle()

			if direction == 'forward'
				sign = -1
			if direction == 'back'
				sign = 1

			@position =
				left: @position.left + sign * speed * Math.cos angle
				top: @position.top + sign * speed * Math.sin angle

			@$tank.css @position

		###
		# shot (create bullet)
		###
		shot: ->
			bulletModel = new BulletModel
			bulletView = new BulletView
				left: parseInt(@$tank.css('left'))
				top: parseInt(@$tank.css('top'))
			, bulletModel, @model

		###
		# rotate tank
		# @param {number} angle
		###
		rotate: (angle) ->
			if !$.browser.msie
				@$tank.css
					'-webkit-transform': "rotate(#{angle}deg)"
					'-moz-transform': "rotate(#{angle}deg)"
					'-o-transform': "rotate(#{angle}deg)"
					'-ms-transform': "rotate(#{angle}deg)"
					'transform': "rotate(#{angle}deg)"
			else
				cos = Math.cos angle
				sin = Math.sin angle
				@$tank.css
					filter: 'progid:DXImageTransform.Microsoft.Matrix(sizingMethod="auto expand", M11 = ' + cos + ', M12 = ' + (-sin) + ', M21 = ' + sin + ', M22 = ' + cos + ')'
					'-ms-filter': 'progid:DXImageTransform.Microsoft.Matrix(sizingMethod="auto expand", M11 = ' + cos + ', M12 = ' + (-sin) + ', M21 = ' + sin + ', M22 = ' + cos + ')'

		###
		# update view
		###
		update: ->
			if Object.keys(@_pressed).length

				@$tank.addClass 'moving'

				for keyCode, value of @_pressed
					switch Number(keyCode)
						when @keyMap.left
							@publish 'leftKeyDown'
						when @keyMap.right
							@publish 'rightKeyDown'
						when @keyMap.top
							@move 'forward'
							@publish 'topKeyDown'
						when @keyMap.bottom
							@move 'back'
							@publish 'bottomKeyDown'
						when @keyMap.space
							now = (new Date()).getTime()
							if now - @lastShotTime > 300
								@shot()
								@$tank.addClass 'shooting'
								setTimeout () =>
									@$tank.removeClass 'shooting'
								, 200
								delete @_pressed[@keyMap.space]
								@lastShotTime = now
			else
				@$tank.removeClass 'moving'

			requestAnimFrame @update.bind(@), @$tank

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
				@model.rotate 'left'
			@view.on 'rightKeyDown', (event) =>
				@model.rotate 'right'

			@model.on 'angleChange', (angle) =>
				@view.rotate angle


	$ () ->
		DOM_CONTAINER = $(document.body)

		$style = $('<style></style>').appendTo $('head')
		$style.html '
		.b-tank{
				z-index: 100;
				position:fixed;
				top:50%;
				left:50%;
				width:60px;
				height:140px;
				margin:-70px 0 -30px;
				background-image: url(data:image/png;base64,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);
				background-size:cover;
				-webkit-animation: tankAnimation .3s steps(10) infinite;
		}

		.b-tank.moving{
			background-image: url(data:image/png;base64,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);
		}

		.b-tank.shooting{
			background-image: url(data:image/png;base64,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);
		}
		
		.b-bullet{z-index:99; position:fixed;width:8px;height:8px;background-color:#000;background-size:cover;border-radius:16px;}
		
		.b-bullet.explode{width:50px;height:50px;background-color:transparent;background-image:url("data:image/gif;base64,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")}
		
		.b-bullet.hole{background-image:url("data:image/png;base64,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")}
		
		@-webkit-keyframes tankAnimation {
			from { background-position: 0 0; }
			to { background-position: 0 1400px; }
		}
			'

		new Tank()

) window, jQuery
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
				background-image:url("data:image/gif;base64,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");
				background-size:cover;
		}

		.b-tank.moving{
			background-image: url(data:image/png;base64,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);
			-webkit-animation: animatedBackground 2s linear infinite;
		}
			
			.b-tank.shooting{background-image:url("data:image/gif;base64,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")}
			
			.b-bullet{z-index:99; position:fixed;width:8px;height:8px;background-color:#000;background-size:cover;border-radius:16px;}
			
			.b-bullet.explode{width:50px;height:50px;background-color:transparent;background-image:url("data:image/gif;base64,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")}
			
			.b-bullet.hole{background-image:url("data:image/png;base64,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")}
			
			@-webkit-keyframes animatedBackground {
				0% { background-position: 0 0; }
				50% { background-position: 60px 0; }
				100% { background-position: 60px 0; }
			}
			'

		new Tank()

) window, jQuery
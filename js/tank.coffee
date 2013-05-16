((window, $) ->
	'use strict'

	DEFAULT_SPEED = 5

	DEFAULT_ANGLE_SPEED = 2

	DEFAULT_BULLET_WIDTH = 2

	DEFAULT_BULLET_HEIGHT = 9

	DEFAULT_BULLET_SPEED = 300

	DEFAULT_BULLET_LENGTH = 250

	DEFAULT_BULLET_LENGTH_RANDOM = 50

	DEFAULT_BULLET_COORD_RANDOM = 50

	DEFAULT_TANK_WIDTH = 75

	DEFAULT_TANK_HEIGHT = 150

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
			# big side
			# @var {number}
			###
			@bigSide = if (@width > @height) then @width else @height

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
			# flag of enable tank
			# @var {boolean}
			###
			@_enabled = false

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
		# destroy model
		###
		destroy: ->


		###
		# Set enabled state
		###
		enable: ->
			@_enabled = true

		###
		# Set disbled state
		###
		disable: ->
			@_enabled = false

		###
		# check state enable
		###
		isEnabled: ->
			@_enabled

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
	# model of bullet
	###
	class BulletModel extends Observer

		constructor: ->
			super

			###
			# bullet speed
			# @var {number}
			###
			@_speed = DEFAULT_BULLET_SPEED

			###
			# bullet length
			# @var {number}
			###
			@_length = DEFAULT_BULLET_LENGTH

			###
			#
			###
			@_randomLength = DEFAULT_BULLET_LENGTH_RANDOM
			@_randomCoord = DEFAULT_BULLET_COORD_RANDOM
			@width = DEFAULT_BULLET_WIDTH
			@height = DEFAULT_BULLET_HEIGHT

		destroy: ->


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
			
			angle = (@tankModel.getAngle() * 180 / Math.PI) - 90
			@$bullet.css
					'-webkit-transform': "rotate(#{angle}deg)"
					'-moz-transform': "rotate(#{angle}deg)"
					'-o-transform': "rotate(#{angle}deg)"
					'-ms-transform': "rotate(#{angle}deg)"
					'transform': "rotate(#{angle}deg)"

			@setCoord coord
			@move @tankModel.getAngle()

		###
		# bullet destroy
		###
		destroy: ->
			@$bullet.remove()


		###
		# set start coordinate
		# @param {number} coord.left X coordinate of tank
		# @param {number} coord.top Y coordinate of tank
		# @param {string} direction current tank direction
		###
		setCoord: (coord, direction) ->
			@position =
				left: coord.left - 10
				top: coord.top - @model.height

			@$bullet.css @position

		###
		# move bullet
		# @param {number} angle
		###
		move: (angle) ->
			length = @model.getLength()
			randomCoord = @model.getRandomCoord()
			signLeft = (Math.round(Math.random() * 100) % 2) ? 1 : -1
			signRight = (Math.round(Math.random() * 100) % 2) ? 1 : -1
			@position = 
				left: @position.left + length * Math.cos(angle + Math.PI) + (signLeft * Math.random() * randomCoord)
				top: @position.top + length * Math.sin(angle + Math.PI) + (signRight * Math.random() * randomCoord)
			@$bullet.animate @position, @model.getSpeed(), 'linear', () =>
				@explode()

		###
		# explode
		###
		explode: ->
			@$bullet.addClass 'explode'
			setTimeout () =>
				console.log 'hole'
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
			@setPosition @$tank.position()
			@lastShotTime = (new Date()).getTime()
			@_pressed = {}
			@_bindEvents()
			@_bullets = []

			@update()

		###
		# tank destroy
		###
		destroy: ->
			
			@$tank.remove()
			@_unbindEvents()
			@clearShots()

		setPosition: (position) ->
			position = $.extend
				left: 0
				top: 0
			, position

			angle = @model.getAngle()
			width = @model.width
			height = @model.height

			@$tank.css position
			@position = position

			@center =
				left: @position.left + (width / 2) + 1 * Math.cos(angle + Math.PI)
				top: @position.top + (height / 2) + 1 * Math.sin(angle + Math.PI)

			@$tank.data
				centerX: @center.left
				centerY: @center.top

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

			@setPosition
				left: @position.left + sign * speed * Math.cos angle
				top: @position.top + sign * speed * Math.sin angle

			$(document.body).trigger 'tank.move'

		###
		# shot (create bullet)
		###
		shot: ->
			bulletModel = new BulletModel
			bulletView = new BulletView @center, bulletModel, @model

			@_bullets.push
				model: bulletModel
				view: bulletView

		###
		# destroy shots
		###
		clearShots: ->
			for bullet in @_bullets
				bullet.model?.destroy()
				bullet.view?.destroy()

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

			$(document.body).trigger 'tank.rotate'

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
			@domHandlers = 
				keydown: (event) =>
					@_onKeyDown event
				keyup: (event) =>
					@_onKeyUp event

			@_$domContainer.on 'keydown', @domHandlers.keydown
			@_$domContainer.on 'keyup', @domHandlers.keyup

		###
		# unbind dom events
		###
		_unbindEvents: ->
			@_$domContainer.off 'keydown', @domHandlers.keydown
			@_$domContainer.off 'keyup', @domHandlers.keyup

		###
		# key down handler
		# @param {jQuery.Event} event jquery event object
		###
		_onKeyDown: (event) ->
			if @model.isEnabled()
				@_pressed[event.keyCode] = true
				event.preventDefault()

		###
		# key up handler
		# @param {jQuery.Event} event jquery event object
		###
		_onKeyUp: (event) ->
			if @model.isEnabled()
				delete @_pressed[event.keyCode]
				event.preventDefault()

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
		# tank destroy
		###
		destroy: ->
			@model.destroy()
			@view.destroy()

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

			$(document.body)
				.on 'tank.enable', (event) =>
					@model.enable()
				.on 'tank.destroy', (event) =>
					@destroy()
				.on 'tank.setPosition', (event, coord) =>
					@view.setPosition coord


	$ () ->
		DOM_CONTAINER = $(document.body)

		new Tank()

) window, jQuery
((window, $) ->
	'use strict'

	DEFAULT_SPEED = 5

	DEFAULT_ANGLE_SPEED = 2

	DEFAULT_BULLET_SPEED = 300

	DEFAULT_BULLET_LENGTH = 300

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
      return  window.requestAnimationFrame       || 
              window.webkitRequestAnimationFrame || 
              window.mozRequestAnimationFrame    || 
              window.oRequestAnimationFrame      || 
              window.msRequestAnimationFrame     || 
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
			@position = 
				left: @position.left + length * Math.cos(angle + Math.PI)
				top: @position.top + length * Math.sin(angle + Math.PI)
			@$bullet.animate @position, @model.getSpeed(), 'linear', () =>
				@$bullet.addClass 'explode'
				setTimeout () =>
					@$bullet.remove()
				, 500

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
			@position = @$tank.position()
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
						@shot()
						delete @_pressed[@keyMap.space]
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
		new Tank()

) window, jQuery
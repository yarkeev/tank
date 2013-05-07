((window, $) ->
	'use strict'

	DEAFAULT_SPEED = 20

	DEAFAULT_BULLET_SPEED = 300

	DEAFAULT_BULLET_LENGTH = 400

	DEFAULT_TANK_WIDTH = 75

	DEFAULT_TANK_HEIGHT = 150

	DEFAULT_BULLET_WIDTH = 16

	DEFAULT_BULLET_HEIGHT = 16

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
			for handler in handlers
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
			@_directrion = 'top'

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
		# Set direction of tank
		# @param {string} direction
		###
		setDirection: (direction) ->
			if @availableDirections.indexOf(direction) != -1
				@_directrion = direction
				@publish 'changeDirection', direction
			else
				@error "unsupport direction #{direction}"

		###
		# return direction of tank
		# @return {string}
		###
		getDirection: ->
			return @_directrion

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
			return @_speed


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

	
	class BulletModel extends Observer

		constructor: ->
			super

			@_speed = DEAFAULT_BULLET_SPEED
			@_length = DEAFAULT_BULLET_LENGTH
			@width = DEFAULT_BULLET_WIDTH
			@height = DEFAULT_BULLET_HEIGHT

		getSpeed: ->
			return @_speed

		getLength: ->
			return @_length

	###
	# View of bullet
	###
	class BulletView extends View

		###
		# @constructor
		###
		constructor: (coord, model, tankModel) ->
			super
			@model = model
			@tankModel = tankModel
			@$bullet = $("<div class='#{CLASSES.bullet.main}'></div>").appendTo @_$domContainer
			@setCoord coord, @tankModel.getDirection()
			@move @tankModel.getDirection()

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

		explode: ->
			@$bullet.addClass 'explode'
			setTimeout () =>
				@$bullet.remove()
			, 500

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
			@_bindEvents()

		###
		# set direction of tank
		# @param {string} direction
		###
		setDirection: (direction) ->
			switch direction
				when 'left'
					angle = -90
				when 'top'
					angle = 0
				when 'right'
					angle = 90
				when 'bottom'
					angle = 180
			@$tank.css
				'-webkit-transform': "rotate(#{angle}deg)"


		###
		# move tank
		# @param {string} direction
		###
		move: (direction) ->
			speed = @model.getSpeed()

			switch direction
				when 'left'
					@$tank.css
						left: parseInt(@$tank.css 'left') - speed
				when 'right'
					@$tank.css
						left: parseInt(@$tank.css 'left') + speed
				when 'top'
					@$tank.css
						top: parseInt(@$tank.css 'top') - speed
				when 'bottom'
					@$tank.css
						top: parseInt(@$tank.css 'top') + speed

		shot: ->
			bulletModel = new BulletModel
			bulletView = new BulletView @$tank.position(), bulletModel, @model

		###
		# bind dom events
		###
		_bindEvents: ->
			@_$domContainer.on 'keydown', (event) =>
				@_onKeyDown event
				event.preventDefault()

		###
		# key down handler
		# @param {jQuery.Event} event jquery event object
		###
		_onKeyDown: (event) ->
			switch event.keyCode
				when @keyMap.left
					@move 'left'
					@publish 'leftKeyDown', event
				when @keyMap.right
					@move 'right'
					@publish 'rightKeyDown', event
				when @keyMap.top
					@move 'top'
					@publish 'topKeyDown', event
				when @keyMap.bottom
					@move 'bottom'
					@publish 'bottomKeyDown', event
				when @keyMap.space
					@shot()

	###
	# class of tank
	###
	class Tank extends Observer

		###
		# @constructor
		###
		constructor: ->
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
			@view.on 'topKeyDown', (event) =>
				@model.setDirection 'top'
			@view.on 'bottomKeyDown', (event) =>
				@model.setDirection 'bottom'

			@model.on 'changeDirection', (direction) =>
				@view.setDirection direction


	$ () ->
		DOM_CONTAINER = $(document.body) 
		new Tank()

) window, jQuery
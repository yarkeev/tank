// Generated by CoffeeScript 1.6.1
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(window, $) {
  'use strict';
  var Base, BulletModel, BulletView, CLASSES, DEBUG, DEFAULT_ANGLE_SPEED, DEFAULT_ANGLE_UPDATE_DELAY, DEFAULT_BULLET_COORD_RANDOM, DEFAULT_BULLET_EXPLODE_TIME, DEFAULT_BULLET_HEIGHT, DEFAULT_BULLET_LENGTH, DEFAULT_BULLET_LENGTH_RANDOM, DEFAULT_BULLET_SPEED, DEFAULT_BULLET_WIDTH, DEFAULT_SPEED, DEFAULT_TANK_HEIGHT, DEFAULT_TANK_WIDTH, DOM_CONTAINER, NetworkInterface, Observer, TIME_OF_DESTROY_ELEMENT, TIME_OF_ERASE_TRAIL, TIME_OF_LIVE_TRAIL, Tank, TankModel, TankView, View, WINDOW_HEIGHT, WINDOW_WIDTH, requestAnimFrame;
  DEFAULT_SPEED = 5;
  DEFAULT_ANGLE_SPEED = 2;
  DEFAULT_BULLET_WIDTH = 2;
  DEFAULT_BULLET_HEIGHT = 9;
  DEFAULT_BULLET_SPEED = 300;
  DEFAULT_BULLET_LENGTH = 250;
  DEFAULT_BULLET_LENGTH_RANDOM = 50;
  DEFAULT_BULLET_COORD_RANDOM = 20;
  DEFAULT_TANK_WIDTH = 60;
  DEFAULT_TANK_HEIGHT = 150;
  DEFAULT_BULLET_EXPLODE_TIME = 500;
  DEFAULT_ANGLE_UPDATE_DELAY = 100;
  DEBUG = false;
  DOM_CONTAINER = null;
  WINDOW_WIDTH = $(window).width();
  WINDOW_HEIGHT = $(window).height();
  TIME_OF_LIVE_TRAIL = 1000;
  TIME_OF_ERASE_TRAIL = 1000;
  TIME_OF_DESTROY_ELEMENT = 300;
  CLASSES = {
    tank: {
      main: 'b-tank',
      trail: 'b-tank-trail'
    },
    bullet: {
      main: 'b-bullet'
    }
  };
  /*
  	# function loop for animations
  */

  requestAnimFrame = (function() {
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
      return window.setTimeout(callback, 1000 / 60);
    };
  })();
  
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
	;
  /*
  	# Base class for all tank classes
  */

  Base = (function() {

    function Base() {}

    /*
    		# flag of enable debug
    		# @var {boolean}
    */


    Base.debug = DEBUG;

    /*
    		# log message in console
    		# @param {string} message
    */


    Base.prototype.log = function(message) {
      if (this.constructor.debug && window.console && window.console.log) {
        return window.console.log(message);
      }
    };

    /*
    		# log error message in console
    		# @param {string} message
    */


    Base.prototype.error = function(message) {
      if (this.constructor.debug && window.console && window.console.log) {
        return window.console.error(message);
      }
    };

    return Base;

  })();
  /*
  	# Pattern observer for event model
  */

  Observer = (function(_super) {

    __extends(Observer, _super);

    /*
    		# @constructor
    */


    function Observer() {
      Observer.__super__.constructor.apply(this, arguments);
      this._subscribers = {};
    }

    /*
    		# subscribe
    		# @param {string} id event identifier
    		# @param {function} callback
    */


    Observer.prototype.on = function(id, callback) {
      id = $.trim(id);
      if (id.length === 0) {
        this.error('incorrect id in Observer.on');
        this;
      }
      if (!$.isFunction(callback)) {
        this.error('incorrect callback in Observer.on');
        this;
      }
      if (this._subscribers[id]) {
        this._subscribers[id].push(callback);
      } else {
        this._subscribers[id] = [callback];
      }
      return this;
    };

    /*
    		# unsubscribe
    		# @param {string} id event identifier
    		# @param {function} callback
    */


    Observer.prototype.off = function(id, callback) {
      var handler, handlers, key, _i, _len;
      id = $.trim(id);
      if (id.length === 0) {
        this.error('incorrect id in Observer.off');
        this;
      }
      if (!$.isFunction(callback)) {
        this._subscribers[id] = [];
      } else {
        handlers = this._subscribers[id];
        for (key = _i = 0, _len = handlers.length; _i < _len; key = ++_i) {
          handler = handlers[key];
          if (handler === callback) {
            handlers[key] = null;
          }
        }
      }
      return this;
    };

    /*
    		# call subscribed callbacks
    		# @param {string} id event identifier
    */


    Observer.prototype.publish = function(id) {
      var args, handler, handlers, key;
      id = $.trim(id);
      if (id.length === 0) {
        this.error('incorrect id in Observer.publish');
      }
      handlers = this._subscribers[id];
      args = Array.prototype.slice.call(arguments, 1);
      for (key in handlers) {
        handler = handlers[key];
        if (handlers.hasOwnProperty(key)) {
          if (handler != null) {
            handler.apply(this, args);
          }
        }
      }
      return this;
    };

    return Observer;

  })(Base);
  NetworkInterface = (function(_super) {

    __extends(NetworkInterface, _super);

    NetworkInterface.prototype.enableState = false;

    NetworkInterface.prototype.host = 'http://localhost';

    NetworkInterface.prototype.port = 8888;

    function NetworkInterface() {
      this.connect();
    }

    NetworkInterface.prototype.connect = function() {
      if (this.enableState) {
        this.socket = io.connect("" + this.host + ":" + this.port);
        return this.socket.on('init', function(data) {
          return console.log(data.sessionId);
        });
      }
    };

    NetworkInterface.prototype.enable = function() {
      return this.enableState = true;
    };

    NetworkInterface.prototype.disable = function() {
      return this.enableState = false;
    };

    NetworkInterface.prototype.on = function(eventId, callback) {
      if (this.enableState) {
        return this.socket.on(eventId, callback);
      }
    };

    NetworkInterface.prototype.emit = function(eventId, data) {
      if (this.enableState) {
        return this.socket.emit(eventId, data);
      }
    };

    return NetworkInterface;

  })(Observer);
  /*
  	# class of view
  */

  View = (function(_super) {

    __extends(View, _super);

    /*
    		# @constructor
    */


    function View() {
      View.__super__.constructor.apply(this, arguments);
      this._$domContainer = DOM_CONTAINER;
    }

    return View;

  })(Observer);
  /*
  	# Model of tank
  */

  TankModel = (function(_super) {

    __extends(TankModel, _super);

    /*
    		# @constructor
    */


    function TankModel() {
      TankModel.__super__.constructor.apply(this, arguments);
      /*
      			# Unique id
      			# @var {string}
      */

      this.id = Math.random().toString(36).substr(2, 16);
      /*
      			# Current directrion
      			# @var {string}
      */

      this._directrion = null;
      /*
      			# Speed of tank in pixel per iteration
      			# @var {number}
      */

      this._speed = DEFAULT_SPEED;
      /*
      			# Angle speed of tank in degrees per iteration
      			# @var {number}
      */

      this._angleSpeed = DEFAULT_ANGLE_SPEED;
      /*
      			# width
      			# @var {number}
      */

      this.width = DEFAULT_TANK_WIDTH;
      /*
      			# height
      			# @var {number}
      */

      this.height = DEFAULT_TANK_HEIGHT;
      /*
      			# big side
      			# @var {number}
      */

      this.bigSide = this.width > this.height ? this.width : this.height;
      /*
      			# angle tank rotate
      			# @var {number}
      */

      this._angle = 0;
      /*
      			# delay of skip rotate
      			# @var {number}
      */

      this._angleUpdateDelay = DEFAULT_ANGLE_UPDATE_DELAY;
      /*
      			# flag of enable tank
      			# @var {boolean}
      */

      this._enabled = false;
      /*
      			# network interface
      			# @var NetworkInterface
      */

      this.network = new NetworkInterface;
    }

    /*
    		# Set direction of tank
    		# @param {string} direction
    */


    TankModel.prototype.rotate = function(direction) {
      if (direction === 'left') {
        this._angle -= this._angleSpeed;
      } else if (direction === 'right') {
        this._angle += this._angleSpeed;
      }
      return this.publish('angleChange', this._angle);
    };

    /*
    		# destroy model
    */


    TankModel.prototype.destroy = function() {};

    /*
    		# Set enabled state
    */


    TankModel.prototype.enable = function() {
      return this._enabled = true;
    };

    /*
    		# Set disbled state
    */


    TankModel.prototype.disable = function() {
      return this._enabled = false;
    };

    /*
    		# check state enable
    */


    TankModel.prototype.isEnabled = function() {
      return this._enabled;
    };

    /*
    		# Set speed of tank
    		# @param {number} speed on pixels per iteration
    */


    TankModel.prototype.setSpeed = function(speed) {
      if (!$.isNumeric(speed)) {
        this.error('incorrect speed in TankModel.setSpeed');
        this;
      }
      return this._speed = speed;
    };

    /*
    		# return speed of tank
    		# return {number}
    */


    TankModel.prototype.getSpeed = function() {
      return this._speed;
    };

    /*
    		# return angle tank rotate
    		# @return {number}
    */


    TankModel.prototype.getAngle = function() {
      return (this._angle + 90) * Math.PI / 180;
    };

    return TankModel;

  })(Observer);
  /*
  	# model of bullet
  */

  BulletModel = (function(_super) {

    __extends(BulletModel, _super);

    function BulletModel() {
      BulletModel.__super__.constructor.apply(this, arguments);
      /*
      			# bullet speed
      			# @var {number}
      */

      this._speed = DEFAULT_BULLET_SPEED;
      /*
      			# bullet length
      			# @var {number}
      */

      this._length = DEFAULT_BULLET_LENGTH;
      /*
      			# random length
      			# @var {number}
      */

      this._randomLength = DEFAULT_BULLET_LENGTH_RANDOM;
      /*
      			# random coord
      			# @var {number}
      */

      this._randomCoord = DEFAULT_BULLET_COORD_RANDOM;
      /*
      			# bullet width
      			# @var {number}
      */

      this.width = DEFAULT_BULLET_WIDTH;
      /*
      			# bullet height
      			# @var {number}
      */

      this.height = DEFAULT_BULLET_HEIGHT;
    }

    /*
    		# destroy model
    */


    BulletModel.prototype.destroy = function() {};

    /*
    		# return speed of bullet
    		# @return {number}
    */


    BulletModel.prototype.getSpeed = function() {
      return this._speed;
    };

    /*
    		# return length of bullet
    		# return {number}
    */


    BulletModel.prototype.getLength = function() {
      return this._length + Math.random() * this._randomLength;
    };

    /*
    		# return random coord
    		# return {number}
    */


    BulletModel.prototype.getRandomCoord = function() {
      return this._randomCoord;
    };

    return BulletModel;

  })(Observer);
  /*
  	# View of bullet
  */

  BulletView = (function(_super) {

    __extends(BulletView, _super);

    /*
    		# @constructor
    		# @param {number} startPosition.left X coordinate of tank
    		# @param {number} startPosition.top Y coordinate of tank
    		# @param {BulletModel} model model of ballet
    		# @param {TankModel} tankModel model of tank
    */


    function BulletView(startPosition, model, tankModel) {
      BulletView.__super__.constructor.apply(this, arguments);
      /*
      			# model of bullet
      			# @var {BulletModel}
      */

      this.model = model;
      /*
      			# model of tank
      			# @var {TankModel}
      */

      this.tankModel = tankModel;
      /*
      			# time of explosion
      			# @var {number}
      */

      this._explodeTime = DEFAULT_BULLET_EXPLODE_TIME;
      /*
      			# dom element of bullet
      			# @var {jQuery}
      */

      this.$bullet = $("<div class='" + CLASSES.bullet.main + "'></div>").appendTo(this._$domContainer);
      /*
      			# start bullet position
      			# @var {object}
      */

      this._startPosition = $.extend({
        left: 0,
        top: 0
      }, startPosition);
      this.init();
    }

    /*
    		# bullet destroy
    */


    BulletView.prototype.destroy = function() {
      return this.$bullet.remove();
    };

    /*
    		# init bullet
    */


    BulletView.prototype.init = function() {
      var bulletAngle, tankAngle, transform;
      tankAngle = this.tankModel.getAngle();
      bulletAngle = (tankAngle * 180 / Math.PI) - 90;
      transform = "rotate(" + bulletAngle + "deg)";
      this.$bullet.css({
        '-webkit-transform': transform,
        '-moz-transform': transform,
        '-o-transform': transform,
        '-ms-transform': transform,
        'transform': transform
      });
      this.setPosition(this._startPosition);
      return this.move(tankAngle);
    };

    /*
    		# set start coordinate
    		# @param {number} position.left X coordinate of tank
    		# @param {number} position.top Y coordinate of tank
    */


    BulletView.prototype.setPosition = function(position) {
      this.position = {
        left: position.left - 10,
        top: position.top - this.model.height
      };
      return this.$bullet.css(this.position);
    };

    /*
    		# move bullet
    		# @param {number} angle
    */


    BulletView.prototype.move = function(angle) {
      var length, randomCoord, signX, signY,
        _this = this;
      length = this.model.getLength();
      randomCoord = this.model.getRandomCoord();
      signX = Math.round(Math.random() * 100) % 2 ? 1 : -1;
      signY = Math.round(Math.random() * 100) % 2 ? 1 : -1;
      this.position = {
        left: this.position.left + length * Math.cos(angle + Math.PI) + (signX * Math.random() * randomCoord),
        top: this.position.top + length * Math.sin(angle + Math.PI) + (signY * Math.random() * randomCoord)
      };
      return this.$bullet.animate(this.position, this.model.getSpeed(), 'linear', function() {
        return _this.explode();
      });
    };

    BulletView.prototype.findExplodeElement = function($el) {
      var $children;
      $children = $el.children();
      if ($children.length) {
        return this.findExplodeElement($children);
      } else {
        return $el;
      }
    };

    /*
    		# explode
    */


    BulletView.prototype.explode = function() {
      var el, scrollTop,
        _this = this;
      this.$bullet.addClass('explode');
      setTimeout(function() {
        return _this.$bullet.addClass('hole');
      }, this._explodeTime);
      scrollTop = $(window).scrollTop();
      el = document.elementFromPoint(this.position.left, this.position.top);
      if (el !== this._$domContainer.get(0)) {
        return this.findExplodeElement($(el)).fadeOut(TIME_OF_DESTROY_ELEMENT);
      }
    };

    return BulletView;

  })(View);
  /*
  	# View of tank
  */

  TankView = (function(_super) {

    __extends(TankView, _super);

    /*
    		# object with key codes
    		# @var {object}
    */


    TankView.prototype.keyMap = {
      left: 37,
      right: 39,
      top: 38,
      bottom: 40,
      space: 32
    };

    /*
    		# @constructor
    		# @param {TankModel} model of tank
    */


    function TankView(model) {
      TankView.__super__.constructor.apply(this, arguments);
      if (!model || !(model instanceof TankModel)) {
        this.error('incorrect model in TankView.constructor');
        this;
      }
      /*
      			# model of tank
      			# @var {TankModel}
      */

      this.model = model;
      /*
      			# time of last shot
      			# @var {number}
      */

      this.lastShotTime = (new Date()).getTime();
      /*
      			# object with pressed keys
      			# @var {object}
      */

      this._pressed = {};
      /*
      			# array of bullets
      			# @var {Array}
      */

      this._bullets = [];
      /*
      			# flag of already tank moved
      			# @var {number}
      */

      this._alreadyMoved = false;
      this.init();
    }

    /*
    		# tank view init
    */


    TankView.prototype.init = function() {
      this.$tank = $("<div class='" + CLASSES.tank.main + "'></div>").appendTo(this._$domContainer);
      this.setPosition(this.$tank.position());
      this._bindEvents();
      return this.update();
    };

    /*
    		# tank destroy
    */


    TankView.prototype.destroy = function() {
      this.$tank.remove();
      this._unbindEvents();
      return this.clearShots();
    };

    /*
    		# set tank position
    */


    TankView.prototype.setPosition = function(position) {
      var angle, height, width;
      position = $.extend({
        left: 0,
        top: 0
      }, position);
      if (position.left > WINDOW_WIDTH || position.left < 0 || position.top < 0 || position.top > WINDOW_HEIGHT) {
        return;
      }
      angle = this.model.getAngle();
      width = this.model.width;
      height = this.model.height;
      this.$tank.css(position);
      this.position = position;
      this.model.network.emit('tank.move', this.position);
      this.center = {
        left: this.position.left + (width / 2) + 1 * Math.cos(angle + Math.PI),
        top: this.position.top + (height / 2) + 1 * Math.sin(angle + Math.PI)
      };
      return this.$tank.data({
        centerX: this.center.left,
        centerY: this.center.top
      });
    };

    /*
    		# move tank
    		# @param {string} direction
    */


    TankView.prototype.move = function(direction) {
      var angle, sign, speed;
      speed = this.model.getSpeed();
      angle = this.model.getAngle();
      if (direction === 'forward') {
        sign = -1;
      }
      if (direction === 'back') {
        sign = 1;
      }
      this.setPosition({
        left: this.position.left + sign * speed * Math.cos(angle),
        top: this.position.top + sign * speed * Math.sin(angle)
      });
      this._$domContainer.trigger('tank.move');
      if (!this._alreadyMoved) {
        this._$domContainer.trigger('tank.firstMove');
        return this._alreadyMoved = true;
      }
    };

    /*
    		# shot (create bullet)
    */


    TankView.prototype.shot = function() {
      var bulletModel, bulletView;
      bulletModel = new BulletModel;
      bulletView = new BulletView(this.center, bulletModel, this.model);
      if (this._bullets.length === 0) {
        this._$domContainer.trigger('tank.firstShot');
      }
      return this._bullets.push({
        model: bulletModel,
        view: bulletView
      });
    };

    TankView.prototype.createTrail = function() {
      var $trail, angle, height, now,
        _this = this;
      if (!this.lastCreateTrail) {
        this.lastCreateTrail = new Date;
      } else {
        now = new Date;
        if (now.getTime() - this.lastCreateTrail.getTime() < 500) {
          return;
        } else {
          this.lastCreateTrail = now;
        }
      }
      angle = (this.model.getAngle() * 180 / Math.PI) - 90;
      height = this.model.height;
      $trail = $("<div class='" + CLASSES.tank.trail + "'></div>").css({
        width: this.model.width,
        height: this.model.height + 3,
        position: 'fixed',
        '-webkit-transform': "rotate(" + angle + "deg)",
        '-moz-transform': "rotate(" + angle + "deg)",
        '-o-transform': "rotate(" + angle + "deg)",
        '-ms-transform': "rotate(" + angle + "deg)",
        'transform': "rotate(" + angle + "deg)"
      }).offset({
        left: this.position.left,
        top: this.position.top
      }).appendTo(this._$domContainer);
      return setTimeout(function() {
        return $trail.fadeOut(TIME_OF_ERASE_TRAIL, function() {
          return $trail.remove();
        });
      }, TIME_OF_LIVE_TRAIL);
    };

    /*
    		# destroy shots
    */


    TankView.prototype.clearShots = function() {
      var bullet, _i, _len, _ref, _ref1, _ref2, _results;
      _ref = this._bullets;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        bullet = _ref[_i];
        if ((_ref1 = bullet.model) != null) {
          _ref1.destroy();
        }
        _results.push((_ref2 = bullet.view) != null ? _ref2.destroy() : void 0);
      }
      return _results;
    };

    /*
    		# rotate tank
    		# @param {number} angle
    */


    TankView.prototype.rotate = function(angle) {
      this.$tank.css({
        '-webkit-transform': "rotate(" + angle + "deg)",
        '-moz-transform': "rotate(" + angle + "deg)",
        '-o-transform': "rotate(" + angle + "deg)",
        '-ms-transform': "rotate(" + angle + "deg)",
        'transform': "rotate(" + angle + "deg)"
      });
      this._$domContainer.trigger('tank.rotate');
      if (!this._alreadyMoved) {
        this._$domContainer.trigger('tank.firstMove');
        return this._alreadyMoved = true;
      }
    };

    /*
    		# update view
    */


    TankView.prototype.update = function() {
      var keyCode, now, value, _ref,
        _this = this;
      if (Object.keys(this._pressed).length) {
        this.$tank.addClass('moving');
        _ref = this._pressed;
        for (keyCode in _ref) {
          value = _ref[keyCode];
          switch (Number(keyCode)) {
            case this.keyMap.left:
              this.publish('leftKeyDown');
              break;
            case this.keyMap.right:
              this.publish('rightKeyDown');
              break;
            case this.keyMap.top:
              this.move('forward');
              this.publish('topKeyDown');
              break;
            case this.keyMap.bottom:
              this.move('back');
              this.publish('bottomKeyDown');
              break;
            case this.keyMap.space:
              now = (new Date()).getTime();
              if (now - this.lastShotTime > 300) {
                this.shot();
                this.$tank.addClass('shooting');
                setTimeout(function() {
                  return _this.$tank.removeClass('shooting');
                }, 200);
                delete this._pressed[this.keyMap.space];
                this.lastShotTime = now;
              }
          }
        }
      } else {
        this.$tank.removeClass('moving');
      }
      return requestAnimFrame(this.update.bind(this), this.$tank);
    };

    /*
    		# bind dom events
    */


    TankView.prototype._bindEvents = function() {
      var _this = this;
      this.domHandlers = {
        keydown: function(event) {
          return _this._onKeyDown(event);
        },
        keyup: function(event) {
          return _this._onKeyUp(event);
        }
      };
      this._$domContainer.on('keydown', this.domHandlers.keydown);
      return this._$domContainer.on('keyup', this.domHandlers.keyup);
    };

    /*
    		# unbind dom events
    */


    TankView.prototype._unbindEvents = function() {
      this._$domContainer.off('keydown', this.domHandlers.keydown);
      return this._$domContainer.off('keyup', this.domHandlers.keyup);
    };

    /*
    		# key down handler
    		# @param {jQuery.Event} event jquery event object
    */


    TankView.prototype._onKeyDown = function(event) {
      if (this.model.isEnabled()) {
        this._pressed[event.keyCode] = true;
        return event.preventDefault();
      }
    };

    /*
    		# key up handler
    		# @param {jQuery.Event} event jquery event object
    */


    TankView.prototype._onKeyUp = function(event) {
      if (this.model.isEnabled()) {
        delete this._pressed[event.keyCode];
        return event.preventDefault();
      }
    };

    return TankView;

  })(View);
  /*
  	# class of tank
  */

  Tank = (function(_super) {

    __extends(Tank, _super);

    /*
    		# @constructor
    */


    function Tank() {
      Tank.__super__.constructor.apply(this, arguments);
      this.model = new TankModel();
      this.view = new TankView(this.model);
      this._bindEvents();
    }

    /*
    		# tank destroy
    */


    Tank.prototype.destroy = function() {
      this.model.destroy();
      return this.view.destroy();
    };

    /*
    		# subscribe on view and model events
    */


    Tank.prototype._bindEvents = function() {
      var _this = this;
      this.view.on('leftKeyDown', function(event) {
        return _this.model.rotate('left');
      });
      this.view.on('rightKeyDown', function(event) {
        return _this.model.rotate('right');
      });
      this.model.on('angleChange', function(angle) {
        return _this.view.rotate(angle);
      });
      return $(document.body).on('tank.enable', function(event) {
        return _this.model.enable();
      }).on('tank.destroy', function(event, data) {
        if (data.id && data.id === _this.model.id) {
          return _this.destroy();
        }
      }).on('tank.setPosition', function(event, coord) {
        return _this.view.setPosition(coord);
      });
    };

    return Tank;

  })(Observer);
  return $(function() {
    DOM_CONTAINER = $(document.body);
    return new Tank();
  });
})(window, jQuery);

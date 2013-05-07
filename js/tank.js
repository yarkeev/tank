// Generated by CoffeeScript 1.6.1
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

(function(window, $) {
  'use strict';
  var Base, BulletModel, BulletView, CLASSES, DEAFAULT_BULLET_LENGTH, DEAFAULT_BULLET_SPEED, DEAFAULT_SPEED, DEBUG, DEFAULT_ANGLE_UPDATE_DELAY, DEFAULT_BULLET_EXPLODE_TIME, DEFAULT_BULLET_HEIGHT, DEFAULT_BULLET_WIDTH, DEFAULT_TANK_HEIGHT, DEFAULT_TANK_WIDTH, DOM_CONTAINER, Observer, Tank, TankModel, TankView, View;
  DEAFAULT_SPEED = 5;
  DEAFAULT_BULLET_SPEED = 300;
  DEAFAULT_BULLET_LENGTH = 400;
  DEFAULT_TANK_WIDTH = 75;
  DEFAULT_TANK_HEIGHT = 150;
  DEFAULT_BULLET_WIDTH = 16;
  DEFAULT_BULLET_HEIGHT = 16;
  DEFAULT_BULLET_EXPLODE_TIME = 500;
  DEFAULT_ANGLE_UPDATE_DELAY = 100;
  DEBUG = true;
  DOM_CONTAINER = null;
  CLASSES = {
    tank: {
      main: 'b-tank'
    },
    bullet: {
      main: 'b-bullet'
    }
  };
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
          console.log(handler);
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
        if (handler != null) {
          handler.apply(this, args);
        }
      }
      return this;
    };

    return Observer;

  })(Base);
  /*
  	# Model of tank
  */

  TankModel = (function(_super) {

    __extends(TankModel, _super);

    /*
    		# available values of property direction
    		# @param {array}
    */


    TankModel.prototype.availableDirections = ['top', 'right', 'bottom', 'left'];

    /*
    		# @constructor
    */


    function TankModel() {
      TankModel.__super__.constructor.apply(this, arguments);
      /*
      			# Current directrion
      			# @var {string}
      */

      this._directrion = null;
      /*
      			# Speed of tank in pixel per iteration
      			# @var {number}
      */

      this._speed = DEAFAULT_SPEED;
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
      			# angle tank rotate
      			# @var {number}
      */

      this._angle = 0;
      /*
      			# last time of update angle
      			# @var {number}
      */

      this._lastUpdateAngle = (new Date()).getTime();
      /*
      			# delay of skip rotate
      			# @var {number}
      */

      this._angleUpdateDelay = DEFAULT_ANGLE_UPDATE_DELAY;
    }

    /*
    		# Set direction of tank
    		# @param {string} direction
    */


    TankModel.prototype.setDirection = function(direction) {
      if (this.availableDirections.indexOf(direction) !== -1) {
        this._directrion = direction;
        clearTimeout(this._angleUpdateTimer);
        this._angleUpdateTimer = setTimeout(this._updateAngle.bind(this), this._angleUpdateDelay);
        return this.publish('changeDirection', direction);
      } else {
        return this.error("unsupport direction " + direction);
      }
    };

    /*
    		# return direction of tank
    		# @return {string}
    */


    TankModel.prototype.getDirection = function() {
      var angle;
      angle = this.getAngle() % 360;
      switch (angle) {
        case 0:
          return 'top';
        case 90:
        case -270:
          return 'right';
        case 180:
        case -180:
          return 'bottom';
        case 270:
        case -90:
          return 'left';
      }
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
      return this._angle;
    };

    /*
    		# update angle rotate
    */


    TankModel.prototype._updateAngle = function() {
      if (this._directrion === 'left') {
        this._angle -= 90;
      }
      if (this._directrion === 'right') {
        this._angle += 90;
      }
      return this.publish('angleChange', this._angle);
    };

    return TankModel;

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
  	# model of bullet
  */

  BulletModel = (function(_super) {

    __extends(BulletModel, _super);

    function BulletModel() {
      BulletModel.__super__.constructor.apply(this, arguments);
      this._speed = DEAFAULT_BULLET_SPEED;
      this._length = DEAFAULT_BULLET_LENGTH;
      this.width = DEFAULT_BULLET_WIDTH;
      this.height = DEFAULT_BULLET_HEIGHT;
    }

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
      return this._length;
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
    		# @param {number} coord.left X coordinate of tank
    		# @param {number} coord.top Y coordinate of tank
    		# @param {BulletModel} model model of ballet
    		# @param {TankModel} tankModel model of tank
    */


    function BulletView(coord, model, tankModel) {
      BulletView.__super__.constructor.apply(this, arguments);
      this.model = model;
      this.tankModel = tankModel;
      this._explodeTime = DEFAULT_BULLET_EXPLODE_TIME;
      this.$bullet = $("<div class='" + CLASSES.bullet.main + "'></div>").appendTo(this._$domContainer);
      this.setCoord(coord, this.tankModel.getDirection());
      this.move(this.tankModel.getDirection());
    }

    /*
    		# set start coordinate
    		# @param {number} coord.left X coordinate of tank
    		# @param {number} coord.top Y coordinate of tank
    		# @param {string} direction current tank direction
    */


    BulletView.prototype.setCoord = function(coord, direction) {
      switch (direction) {
        case 'left':
          coord.top -= this.tankModel.width / 2 + this.model.height / 2;
          break;
        case 'right':
          coord.top -= this.tankModel.width / 2 + this.model.height / 2;
          coord.left += this.tankModel.height;
          break;
        case 'top':
          coord.left += this.tankModel.width / 2 - this.model.width / 2;
          coord.top -= this.tankModel.height / 2;
          break;
        case 'bottom':
          coord.left += this.tankModel.width / 2 - this.model.width / 2;
          coord.top += this.tankModel.height / 2 - this.model.height / 2;
      }
      return this.$bullet.css(coord);
    };

    /*
    		# move bullet
    		# @param {string} direction
    */


    BulletView.prototype.move = function(direction) {
      switch (direction) {
        case 'left':
          return this.$bullet.animate({
            left: "-=" + (this.model.getLength())
          }, this.model.getSpeed(), 'linear', this.explode.bind(this));
        case 'right':
          return this.$bullet.animate({
            left: "+=" + (this.model.getLength())
          }, this.model.getSpeed(), 'linear', this.explode.bind(this));
        case 'top':
          return this.$bullet.animate({
            top: "-=" + (this.model.getLength())
          }, this.model.getSpeed(), 'linear', this.explode.bind(this));
        case 'bottom':
          return this.$bullet.animate({
            top: "+=" + (this.model.getLength())
          }, this.model.getSpeed(), 'linear', this.explode.bind(this));
      }
    };

    /*
    		# explode
    */


    BulletView.prototype.explode = function() {
      var _this = this;
      this.$bullet.addClass('explode');
      return setTimeout(function() {
        return _this.$bullet.remove();
      }, this._explodeTime);
    };

    return BulletView;

  })(View);
  /*
  	# View of tank
  */

  TankView = (function(_super) {

    __extends(TankView, _super);

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
      this.model = model;
      this.$tank = $("<div class='" + CLASSES.tank.main + "'></div>").appendTo(this._$domContainer);
      this.$tank.css(this.$tank.position());
      this._pressed = {};
      this._bindEvents();
      setInterval(this.update.bind(this), 10);
    }

    /*
    		# move tank
    		# @param {string} directionX
    */


    TankView.prototype.move = function(directionX) {
      var directionY, position, sign, speed;
      speed = this.model.getSpeed();
      directionY = this.model.getDirection();
      position = {};
      if (directionX === 'forward') {
        sign = 1;
      }
      if (directionX === 'back') {
        sign = -1;
      }
      switch (directionY) {
        case 'top':
          position.top = parseInt(this.$tank.css('top')) - sign * speed;
          break;
        case 'right':
          position.left = parseInt(this.$tank.css('left')) + sign * speed;
          break;
        case 'bottom':
          position.top = parseInt(this.$tank.css('top')) + sign * speed;
          break;
        case 'left':
          position.left = parseInt(this.$tank.css('left')) - sign * speed;
      }
      return this.$tank.css(position);
    };

    /*
    		# shot (create bullet)
    */


    TankView.prototype.shot = function() {
      var bulletModel, bulletView;
      bulletModel = new BulletModel;
      return bulletView = new BulletView(this.$tank.position(), bulletModel, this.model);
    };

    /*
    		# rotate tank
    		# @param {number} angle
    */


    TankView.prototype.rotate = function(angle) {
      return this.$tank.css({
        '-webkit-transform': "rotate(" + angle + "deg)"
      });
    };

    /*
    		# update view
    */


    TankView.prototype.update = function() {
      var keyCode, value, _ref, _results;
      _ref = this._pressed;
      _results = [];
      for (keyCode in _ref) {
        value = _ref[keyCode];
        switch (Number(keyCode)) {
          case this.keyMap.left:
            console.log('left');
            _results.push(this.publish('leftKeyDown', event));
            break;
          case this.keyMap.right:
            console.log('right');
            _results.push(this.publish('rightKeyDown', event));
            break;
          case this.keyMap.top:
            console.log('top');
            this.move('forward');
            _results.push(this.publish('topKeyDown', event));
            break;
          case this.keyMap.bottom:
            console.log('bottom');
            this.move('back');
            _results.push(this.publish('bottomKeyDown', event));
            break;
          case this.keyMap.space:
            this.shot();
            _results.push(delete this._pressed[this.keyMap.space]);
            break;
          default:
            _results.push(void 0);
        }
      }
      return _results;
    };

    /*
    		# bind dom events
    */


    TankView.prototype._bindEvents = function() {
      var _this = this;
      this._$domContainer.on('keydown', function(event) {
        _this._onKeyDown(event);
        return event.preventDefault();
      });
      return this._$domContainer.on('keyup', function(event) {
        _this._onKeyUp(event);
        return event.preventDefault();
      });
    };

    /*
    		# key down handler
    		# @param {jQuery.Event} event jquery event object
    */


    TankView.prototype._onKeyDown = function(event) {
      return this._pressed[event.keyCode] = true;
    };

    /*
    		# key up handler
    		# @param {jQuery.Event} event jquery event object
    */


    TankView.prototype._onKeyUp = function(event) {
      return delete this._pressed[event.keyCode];
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
    		# subscribe on view and model events
    */


    Tank.prototype._bindEvents = function() {
      var _this = this;
      this.view.on('leftKeyDown', function(event) {
        return _this.model.setDirection('left');
      });
      this.view.on('rightKeyDown', function(event) {
        return _this.model.setDirection('right');
      });
      return this.model.on('angleChange', function(angle) {
        return _this.view.rotate(angle);
      });
    };

    return Tank;

  })(Observer);
  return $(function() {
    DOM_CONTAINER = $(document.body);
    return new Tank();
  });
})(window, jQuery);

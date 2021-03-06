(function() {
  var Animal, Horse, Snake, a, a_googol, activity, b, bottle, c, change_a_and_set_b, decoration, dense_object_literal, eldest, empty, even, exponents, food, hex, i, infinity, multiline, nan, negative, odd, race, run_loop, sam, spaced_out_multiline_object, square, stooges, story, sum, supper, tom, v_1, v_2, wednesday, _i, _len, _len2, _ref, _ref2;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  square = function(x) {
    return x * x;
  };
  sum = function(x, y) {
    return x + y;
  };
  odd = function(x) {
    return x % 2 !== 0;
  };
  even = function(x) {
    return x % 2 === 0;
  };
  run_loop = function() {
    fire_events(function(e) {
      return e.stopPropagation();
    });
    listen();
    return wait();
  };
  dense_object_literal = {
    one: 1,
    two: 2,
    three: 3
  };
  spaced_out_multiline_object = {
    pi: 3.14159,
    list: [1, 2, 3, 4],
    regex: /match[ing](every|thing|\/)/gi,
    three: new Idea,
    inner_obj: {
      freedom: function() {
        return _.freedom();
      }
    }
  };
  stooges = [
    {
      moe: 45
    }, {
      curly: 43
    }, {
      larry: 46
    }
  ];
  exponents = [
    (function(x) {
      return x;
    }), (function(x) {
      return x * x;
    }), (function(x) {
      return x * x * x;
    })
  ];
  empty = [];
  multiline = ['line one', 'line two'];
  if (submarine.shields_up) {
    full_speed_ahead();
    fire_torpedos();
  } else if (submarine.sinking) {
    abandon_ship();
  } else {
    run_away();
  }
  eldest = 25 > 21 ? liz : marge;
  if (war_hero) {
    decoration = medal_of_honor;
  }
  if (!coffee) {
    go_to_sleep();
  }
  race = function() {
    run();
    walk();
    crawl();
    if (tired) {
      return sleep();
    }
    return race();
  };
  good || (good = evil);
  wine && (wine = cheese);
  (moon.turn(360)).shapes[3].move({
    x: 45,
    y: 30
  }).position['top'].offset('x');
  a = b = c = 5;
  callback(function(e) { e.stop(); });
  try {
    all_hell_breaks_loose();
    dogs_and_cats_living_together();
    throw "up";
  } catch (error) {
    print(error);
  } finally {
    clean_up();
  }
  try {
    all_hell_breaks_loose();
  } catch (error) {
    print(error);
  } finally {
    clean_up();
  }
  while (demand > supply) {
    sell();
    restock();
  }
  while (supply > demand) {
    buy();
  }
  while (true) {
    if (broken) {
      break;
    }
    if (continuing) {
      continue;
    }
  }
  !!true;
  v_1 = 5;
  change_a_and_set_b = function() {
    var v_2;
    v_1 = 10;
    return v_2 = 15;
  };
  v_2 = 20;
  _ref = ['toast', 'cheese', 'wine'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    food = _ref[_i];
    supper = food.capitalize();
  }
  _ref2 = ['soda', 'wine', 'lemonade'];
  for (i = 0, _len2 = _ref2.length; i < _len2; i++) {
    bottle = _ref2[i];
    if (even(i)) {
      drink(bottle);
    }
  }
  activity = (function() {
    switch (day) {
      case "Tuesday":
        return eat_breakfast();
      case "Sunday":
        return go_to_church();
      case "Saturday":
        return go_to_the_park();
      case "Wednesday":
        if (day === bingo_day) {
          return go_to_bingo();
        } else {
          eat_breakfast();
          go_to_work();
          return eat_dinner();
        }
        break;
      default:
        return go_to_work();
    }
  })();
  wednesday = function() {
    eat_breakfast();
    go_to_work();
    return eat_dinner();
  };
  story = "Lorem ipsum dolor \"sit\" amet, consectetuer adipiscing elit,sed diam nonummy nibh euismod tincidunt ut laoreet dolore magnaaliquam erat volutpat. Ut wisi enim ad.";
  Animal = (function() {
    function Animal() {}
    (function(name) {
      this.name = name;
    });
    Animal.prototype.move = function(meters) {
      return alert(this.name + " moved " + meters + "m.");
    };
    return Animal;
  })();
  Snake = (function() {
    __extends(Snake, Animal);
    function Snake() {
      Snake.__super__.constructor.apply(this, arguments);
    }
    Snake.prototype.move = function() {
      alert('Slithering...');
      return Snake.__super__.move.call(this, 5);
    };
    return Snake;
  })();
  Horse = (function() {
    __extends(Horse, Animal);
    function Horse() {
      Horse.__super__.constructor.apply(this, arguments);
    }
    Horse.prototype.move = function() {
      alert('Galloping...');
      return Horse.__super__.move.call(this, 45);
    };
    return Horse;
  })();
  sam = new Snake("Sammy the Snake");
  tom = new Horse("Tommy the Horse");
  sam.move();
  tom.move();
  a_googol = 1e100;
  hex = 0xff0000;
  negative = -1.0;
  infinity = Infinity;
  nan = NaN;
  delete secret.identity;
}).call(this);

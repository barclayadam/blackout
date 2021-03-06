(function() {
  var runtime;
  runtime = function(N) {
    var n, sum, t, _ref;
    _ref = [0, 0], sum = _ref[0], t = _ref[1];
    for (n = 1; 1 <= N ? n <= N : n >= N; 1 <= N ? n++ : n--) {
      sum += 2 * t;
      t = n - 1 + sum / n;
    }
    return t;
  };
  console.log(runtime(3) === 2.6666666666666665);
  console.log(runtime(5) === 7.4);
  console.log(runtime(8) === 16.92142857142857);
}).call(this);

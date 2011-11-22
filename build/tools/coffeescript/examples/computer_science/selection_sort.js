(function() {
  var selection_sort;
  selection_sort = function(list) {
    var i, k, len, min, v, _len, _ref, _ref2;
    len = list.length;
    for (i = 0; 0 <= len ? i < len : i > len; 0 <= len ? i++ : i--) {
      min = i;
      _ref = list.slice(i + 1);
      for (k = 0, _len = _ref.length; k < _len; k++) {
        v = _ref[k];
        if (v < list[min]) {
          min = k;
        }
      }
      if (i !== min) {
        _ref2 = [list[min], list[i]], list[i] = _ref2[0], list[min] = _ref2[1];
      }
    }
    return list;
  };
  console.log(selection_sort([3, 2, 1]).join(' ') === '1 2 3');
  console.log(selection_sort([9, 2, 7, 0, 1]).join(' ') === '0 1 2 7 9');
}).call(this);

require('coffee-script')
Redis = require('redis').createClient()
Amico = require('../lib/')
Amico.configure(function() {
  this.redis = Redis;
})

var inProgress = false;
var asyncResults;

asyncTest = function(actionCallback) {
  inProgress = true;
  actionCallback()
}

asyncDone = function () {
  inProgress = false;
  asyncResults = arguments;
}
whenDone = function(callback) {
  waitsFor(function() {
    return (inProgress == false);
  })
  runs(function() {
    callback.apply(this, asyncResults); 
  })
}

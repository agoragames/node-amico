require('coffee-script')
require('should')
Redis = require('redis').createClient()
Amico = require('../lib/')
Amico.configure(function() {
  this.redis = Redis;
})

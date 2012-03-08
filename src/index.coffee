Hash = require 'hashish'

getEpoch = ->
  date = new Date()
  return date.getTime()

Amico =
  redis: null
  namespace: 'amico'
  followingKey: 'following'
  followersKey: 'followers'
  blockedKey: 'blocked'
  reciprocatedKey: 'reciprocated'
  scopeKey: 'default'
  pageSize: 25

  configure: (config) ->
   config.apply(@)

  follow: (fromId, toId, scope = @scopeKey, callback) ->
    if fromId is toId
      if callback?
        return callback(false)
      else
        return false

    self = @

    @isBlocked toId, fromId, scope, (result) =>
      if result == true
        if callback?
          return callback(false)
        else
          return false
      else
        @redis.multi()
          .zadd("#{@namespace}:#{@followingKey}:#{scope}:#{fromId}", getEpoch(), toId)
          .zadd("#{@namespace}:#{@followersKey}:#{scope}:#{toId}", getEpoch(), fromId)
          .exec (err, replies) ->
            self.isReciprocated fromId, toId, scope, (result) ->
              if result == true
                self.redis.multi()
                  .zadd("#{self.namespace}:#{self.reciprocatedKey}:#{scope}:#{fromId}", getEpoch(), toId)
                  .zadd("#{self.namespace}:#{self.reciprocatedKey}:#{scope}:#{toId}", getEpoch(), fromId)
                  .exec (err, replies) ->
                    if callback?
                      callback(true)
              else
                if callback?
                  callback(true)

  unfollow: (fromId, toId, scope = @scopeKey, callback) ->
    if fromId is toId
      if callback?
        return callback(false)
      else
        return false

    @redis.multi()
      .zrem("#{@namespace}:#{@followingKey}:#{scope}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followersKey}:#{scope}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{toId}", fromId)
      .exec (err, replies) ->
        if callback?
          callback(true)

  block: (fromId, toId, scope = @scopeKey, callback) ->
    if fromId is toId
      if callback?
        return callback(false)
      else
        return false

    @redis.multi()
      .zrem("#{@namespace}:#{@followingKey}:#{scope}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followingKey}:#{scope}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@followersKey}:#{scope}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followersKey}:#{scope}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{toId}", fromId)
      .zadd("#{@namespace}:#{@blockedKey}:#{scope}:#{fromId}", getEpoch(), toId)
      .exec (err, replies) ->
        if err?
          if callback?
            callback(false)
        else if callback?
          callback(true)

  unblock: (fromId, toId, scope = @scopeKey, callback) ->
    if !callback?
      callback = ->
    if fromId == toId
      return false
  
    @redis.zrem "#{@namespace}:#{@blockedKey}:#{scope}:#{fromId}", toId, (err) ->
      if err?
        callback(false)
      else
        callback(true)

  followingCount: (id, scope = @scopeKey, callback) ->
    @redis.zcard "#{@namespace}:#{@followingKey}:#{scope}:#{id}", (err, count) ->
      callback(count)

  followersCount: (id, scope = @scopeKey, callback) ->
    @redis.zcard "#{@namespace}:#{@followersKey}:#{scope}:#{id}", (err, count) ->
      callback(count)

  blockedCount: (id, scope = @scopeKey, callback) ->
    @redis.zcard "#{@namespace}:#{@blockedKey}:#{scope}:#{id}", (err, count) ->
      callback(count)

  reciprocatedCount: (id, scope = @scopeKey, callback) ->
    @redis.zcard "#{@namespace}:#{@reciprocatedKey}:#{scope}:#{id}", (err, count) ->
      callback(count)

  isFollowing: (id, followingId, scope = @scopeKey, callback) ->
    @redis.zscore "#{@namespace}:#{@followingKey}:#{scope}:#{id}", followingId, (err, score) ->
      callback(score?)

  isFollower: (id, followerId, scope = @scopeKey, callback) ->
    @redis.zscore "#{@namespace}:#{@followersKey}:#{scope}:#{id}", followerId, (err, score) ->
      callback(score?)

  isBlocked: (id, blockedId, scope = @scopeKey, callback) ->
    @redis.zscore "#{@namespace}:#{@blockedKey}:#{scope}:#{id}", blockedId, (err, score) ->
      callback(score?)

  isReciprocated: (fromId, toId, scope = @scopeKey, callback) ->
    self = @
    @isFollowing fromId, toId, scope, (result) ->
      if result == true
        self.isFollowing toId, fromId, scope, (result) ->
          callback(result)
      else
        callback(false)

  following: (id, {pageOptions, scope}, callback) ->
    pageOptions ?= @defaultOptions()
    scope ?= @scopeKey
    @members("#{@namespace}:#{@followingKey}:#{scope}:#{id}", pageOptions, callback)

  followers: (id, {pageOptions, scope}, callback) ->
    pageOptions ?= @defaultOptions()
    scope ?= @scopeKey
    @members("#{@namespace}:#{@followersKey}:#{scope}:#{id}", pageOptions, callback)

  blocked: (id, {pageOptions, scope}, callback) ->
    pageOptions ?= @defaultOptions()
    scope ?= @scopeKey
    @members("#{@namespace}:#{@blockedKey}:#{scope}:#{id}", pageOptions, callback)

  reciprocated: (id, {pageOptions, scope}, callback) ->
    pageOptions ?= @defaultOptions()
    scope ?= @scopeKey
    @members("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{id}", pageOptions, callback)

  followingPageCount: (id, {pageSize, scope}, callback) ->
    pageSize ?= @pageSize
    scope ?= @scopeKey
    @totalPages("#{@namespace}:#{@followingKey}:#{scope}:#{id}", pageSize, callback)

  followersPageCount: (id, {pageSize, scope}, callback) ->
    pageSize ?= @pageSize
    scope ?= @scopeKey
    @totalPages("#{@namespace}:#{@followersKey}:#{scope}:#{id}", pageSize, callback)

  blockedPageCount: (id, {pageSize, scope}, callback) ->
    pageSize ?= @pageSize
    scope ?= @scopeKey
    @totalPages("#{@namespace}:#{@blockedKey}:#{scope}:#{id}", pageSize, callback)

  reciprocatedPageCount: (id, {pageSize, scope}, callback) ->
    pageSize ?= @pageSize
    scope ?= @scopeKey
    @totalPages("#{@namespace}:#{@reciprocatedKey}:#{scope}:#{id}", pageSize, callback)

  defaultOptions: ->
    {
      pageSize: @pageSize
      page: 1
    }

  totalPages: (key, pageSize, callback) ->
    @redis.zcard key, (err, card) ->
      callback(Math.ceil(card / pageSize))

  members: (key, options, callback) ->
    if options?
      options = Hash.merge(@defaultOptions(), options)
    else
      options = @defaultOptions()

    if options.page < 1
      options.page = 1

    @totalPages key, options.pageSize, (pages) =>
      if options.page > pages
        options.page = pages

      indexForRedis = options.page - 1
      startingOffset = (indexForRedis * options.pageSize)

      if startingOffset < 0
        startingOffset = 0

      endingOffset = (startingOffset + options.pageSize) - 1

      @redis.zrevrange key, startingOffset, endingOffset, (err, results) ->
        callback(results)

module.exports = Amico

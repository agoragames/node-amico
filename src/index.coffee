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
  pageSize: 25

  configure: (config) ->
   config.apply(@)

  follow: (fromId, toId, callback) ->
    if fromId == toId
      if callback?
        callback(false)
      else
        return false

    self = @

    @isBlocked toId, fromId, (result) =>
      if result == true
        if callback?
          return callback(false)
        else
          return false
      else
        @redis.multi()
          .zadd("#{@namespace}:#{@followingKey}:#{fromId}", getEpoch(), toId)
          .zadd("#{@namespace}:#{@followersKey}:#{toId}", getEpoch(), fromId)
          .exec (err, replies) ->
            console.log "Replies: #{replies.inspect}"
            self.isReciprocated fromId, toId, (result) ->
              if result == true
                self.redis.multi()
                  .zadd("#{self.namespace}:#{self.reciprocatedKey}:#{fromId}", getEpoch(), toId)
                  .zadd("#{self.namespace}:#{self.reciprocatedKey}:#{toId}", getEpoch(), fromId)
                  .exec (err, replies) ->
                    console.log "Replies: #{replies.inspect}"
                    if callback?
                      callback(true)

  unfollow: (fromId, toId, callback) ->
    if fromId == toId
      if callback?
        callback(false)
      else
        return false

    @redis.multi()
      .zrem("#{@namespace}:#{@followingKey}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followersKey}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{toId}", fromId)
      .exec (err, replies) ->
        if callback?
          callback(true)

  block: (fromId, toId, callback) ->
    if fromId == toId
      if callback?
        callback(false)
      else
        return false

    @redis.multi()
      .zrem("#{@namespace}:#{@followingKey}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followingKey}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@followersKey}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@followersKey}:#{toId}", fromId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{fromId}", toId)
      .zrem("#{@namespace}:#{@reciprocatedKey}:#{toId}", fromId)
      .zadd("#{@namespace}:#{@blockedKey}:#{fromId}", getEpoch(), toId)
      .exec (err, replies) ->
        if err?
          if callback?
            callback(false)
        else if callback?
          callback(true)

  unblock: (fromId, toId, callback) ->
    if !callback?
      callback = ->
    if fromId == toId
      return false

    @redis.zrem("#{@namespace}:#{@blockedKey}:#{fromId}", toId, callback)

  following_count: (id, callback) ->
    @redis.zcard("#{@namespace}:#{@followingKey}:#{id}", callback)

  followers_count: (id, callback) ->
    @redis.zcard("#{@namespace}:#{@followersKey}:#{id}", callback)

  blocked_count: (id, callback) ->
    @redis.zcard("#{@namespace}:#{@blockedKey}:#{id}", callback)

  reciprocated_count: (id, callback) ->
    @redis.zcard("#{@namespace}:#{@reciprocatedKey}:#{id}", callback)



  isFollowing: (id, followingId, callback) ->
    @redis.zscore "#{@namespace}:#{@followingKey}:#{id}", followingId, (err, score) ->
      callback((score != null))

  isFollower: (id, followerId, callback) ->
    @redis.zscore "#{@namespace}:#{@followersKey}:#{id}", followerId, (err, score) ->
      callback((score != null))

  isBlocked: (id, blockedId, callback) ->
    @redis.zscore "#{@namespace}:#{@blockedKey}:#{id}", blockedId, (err, score) ->
      callback((score != null))

  isReciprocated: (fromId, toId, callback) ->
    @isFollowing fromId, toId, (err, result) =>
      if result == true
        @isFollowing toId, fromId, (err, result) ->
          callback(result)
      else
        callback(false)

  following: (id, options, callback) ->
    if !callback?
      callback = options
      options = {}

    @members("#{@namespace}:#{@followingKey}:#{id}", options, callback)

  followers: (id, options, callback) ->
    if !callback?
      callback = options
      options = {}

    @members("#{@namespace}:#{@followingKey}:#{id}", options, callback)

  blocked: (id, options, callback) ->
    if !callback?
      callback = options
      options = {}

    @members("#{@namespace}:#{@blockedKey}:#{id}", options, callback)

  reciprocated: (id, options, callback) ->
    if !callback?
      callback = options
      options = {}

    @members("#{@namespace}:#{@reciprocatedKey}:#{id}", options, callback)

  following_page_count: (id, pageSize, callback) ->
    if !callback?
      callback = pageSize
      pageSize = @pageSize

    @totalPages("#{@namespace}:#{@followingKey}:#{id}", pageSize, callback)

  followers_page_count: (id, pageSize, callback) ->
    if !callback?
      callback = pageSize
      pageSize = @pageSize

    @totalPages("#{@namespace}:#{@followersKey}:#{id}", pageSize, callback)

  blocked_page_count: (id, pageSize, callback) ->
    if !callback?
      callback = pageSize
      pageSize = @pageSize

    @totalPages("#{@namespace}:#{@blockedKey}:#{id}", pageSize, callback)

  reciprocated_page_count: (id, pageSize, callback) ->
    if !callback?
      callback = pageSize
      pageSize = @pageSize

    @totalPages("#{@namespace}:#{@reciprocatedKey}:#{id}", pageSize, callback)

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
      options = Hash.merge(Hash(@defaultOptions), Hash(options))
    else
      options = @defaultOptions

    if options.page < 1
      options.page = 1

    @totalPages (pages) ->
      if options.page > pages
        options.page = pages

      indexForRedis = options.page - 1
      startingOffset = (indexForRedis * options.pageSize)

      if startingOffset < 0
        startingOffset = 0

      endingOffset = (startingOffset + options.pageSize)

      @redis.zrevrange(key, startingOffset, endingOffset, false, callback)

module.exports = Amico

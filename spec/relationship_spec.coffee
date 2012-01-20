describe 'Amico relationships', ->
  describe 'Amico#follow', ->

    beforeEach ->
      Amico.redis.flushdb()

    it 'should allow you to follow', ->
      Amico.follow(1,11)
      asyncTest ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
          asyncDone(score)
      whenDone (value) ->
        expect(value).toEqual(1)

      asyncTest ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followersKey}:11", (err, score) ->
          asyncDone(score)
      whenDone (value) ->
        expect(value).toEqual(1)

    it 'should not allow you to follow yourself', ->
      Amico.follow(1,1)

      asyncTest ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
          asyncDone(score)
      whenDone (value) ->
        expect(value).toEqual(0)

      asyncTest ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followersKey}:1", (err, score) ->
          asyncDone(score)
      whenDone (value) ->
        expect(value).toEqual(0)

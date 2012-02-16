describe 'Amico relationships', ->
  describe 'Amico#follow', ->

    beforeEach ->
      Amico.redis.del "#{Amico.namespace}:#{Amico.followingKey}:1", (e,r) ->
      Amico.redis.del "#{Amico.namespace}:#{Amico.followersKey}:11", (e,r) ->
      
    describe 'Following others', ->
      it 'should return true', (done) ->
        Amico.follow 1, 11, (result) ->
          result.should.be.true
          done()

      it 'should add the followingKey', (done) ->
        Amico.follow 1,11, (result) ->
          Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
            score.should.equal(1)
            done()

      it 'should add the followersKey', (done) ->
        Amico.follow 1,11, (result) ->
          Amico.redis.zcard "#{Amico.namespace}:#{Amico.followersKey}:11", (err, score) ->
            score.should.equal(1)
            done()

    describe 'Following yourself', ->
      it 'should return false', (done) ->
        Amico.follow 1, 1, (result) ->
          result.should.be.false
          done()

      it 'should not set the followingKey', (done) ->
        Amico.follow 1, 1, (result) ->
          Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
            score.should.equal(0)
            done()

      it 'should not set the followersKey', (done) ->
        Amico.follow 1, 1, (result) ->
          Amico.redis.zcard "#{Amico.namespace}:#{Amico.followersKey}:11", (err, score) ->
            score.should.equal(0)
            done()

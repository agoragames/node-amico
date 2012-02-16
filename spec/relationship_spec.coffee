purgeId = (id) ->
  Amico.redis.del "#{Amico.namespace}:#{Amico.followingKey}:#{id}", ->
  Amico.redis.del "#{Amico.namespace}:#{Amico.followersKey}:#{id}", ->
  Amico.redis.del "#{Amico.namespace}:#{Amico.reciprocatedKey}:#{id}", ->
  Amico.redis.del "#{Amico.namespace}:#{Amico.blockedKey}:#{id}", ->

describe 'Amico relationships', ->
  beforeEach ->
    for num in [1,11,12]
      purgeId(num)

  describe 'Amico#follow', ->
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

  describe 'Amico#unfollow', ->
    beforeEach (done) ->
      Amico.follow 1,11, (result) ->
        result.should.be.true
        done()

    it 'should allow you to unfollow', (done) ->
      Amico.unfollow 1, 11, (result) ->
        result.should.be.true
        done()

    it 'should remove the followingKey', (done) ->
      Amico.unfollow 1, 11, (result) ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
          score.should.eql(0)
          done()

    it 'should remove the followerKey', (done) ->
      Amico.unfollow 1, 11, (result) ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followersKey}:11", (err, score) ->
          score.should.eql(0)
          done()
    describe 'when reciprocated', ->
      beforeEach (done) ->
        Amico.follow 11, 1, (result) ->
          done()

      it 'should have no reciprocatingKey', (done) ->
        Amico.unfollow 1, 11, (result) ->
          Amico.redis.zcard "#{Amico.namespace}:#{Amico.reciprocatedKey}:1", (err, score) ->
            score.should.eql(0)
            Amico.redis.zcard "#{Amico.namespace}:#{Amico.reciprocatedKey}:11", (err, score) ->
              score.should.eql(0)
              done()
  describe 'Amico#block', ->
    beforeEach (done) ->
      Amico.follow 1, 11, (result) ->
        done()

    it 'should return true when successful', (done) ->
      Amico.block 1, 11, (result) ->
        result.should.be.true
        done()

    it 'should also unfollow', (done) ->
      Amico.block 1, 11, (result) ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.followingKey}:1", (err, score) ->
          score.should.equal(0)
          done()

    it 'should add to blockedKey for blocker', (done) ->
      Amico.block 1, 11, (result) ->
        Amico.redis.zcard "#{Amico.namespace}:#{Amico.blockedKey}:1", (err, score) ->
          score.should.equal(1)
          done()
    
    it 'should not allow you to block yourself', (done) ->
      Amico.block 1, 1, (result) ->
        result.should.be.false
        done()

  describe 'Amico#unblock', ->
    it 'should allow you to unblock someone you have blocked', (done) ->
      Amico.block 1, 11, (result) ->
        Amico.isBlocked 1, 11, (result) ->
          result.should.be.true

          Amico.unblock 1, 11, (result) ->
            result.should.be.true
            Amico.isBlocked 1, 11, (result) ->
              result.should.be.false
              done()

  describe 'Amico#isFollowing', ->
    it 'should return that you are following', (done) ->
      Amico.follow 1, 11, ->
        Amico.isFollowing 1, 11, (result) ->
          result.should.be.true
          Amico.isFollowing 11, 1, (result) ->
            result.should.be.false
            done()

  describe 'Amico#isFollower', ->
    it 'should return that you are being followed', (done) ->
      Amico.follow 1, 11, ->
        Amico.isFollower 11, 1, (result) ->
          result.should.be.true
          Amico.isFollower 1, 11, (result) ->
            result.should.be.false
            done()

  describe 'Amico#isBlocked', ->
    it 'should return that someone is being blocked', (done) ->
      Amico.block 1, 11, ->
        Amico.isBlocked 1, 11, (result) ->
          result.should.be.true
          Amico.isFollowing 11, 1, (result) ->
            result.should.be.false
            done()

  describe 'Amico#isReciprocated', ->
    it 'should return true if both individuals are following', (done) ->
      Amico.follow 1, 11, ->
          Amico.follow 11, 1, ->
            Amico.isReciprocated 1, 11, (result) ->
              result.should.be.true
              done()
    it 'should return false if both individuals are not following', (done) ->
      Amico.follow 1, 11, ->
        Amico.isReciprocated 1, 11, (result) ->
          result.should.be.false
          done()

  describe 'Amico#following', ->
    it 'should return the correct list', (done) ->
      Amico.follow 1, 11, ->
        Amico.follow 1, 12, ->
          Amico.following 1, (results) ->
            results.should.eql(['12', '11'])
            done()

  describe 'Amico#followers', ->
    it 'should return the correct list', (done) ->
      Amico.follow 1, 11, ->
        Amico.follow 12, 11, ->
          Amico.followers 11, (results) ->
            results.should.eql(['12', '1'])
            done()

  describe 'Amico#blocked', ->
    it 'should return the correct list', (done) ->
      Amico.block 1, 11, ->
        Amico.block 1, 12, ->
          Amico.blocked 1, (results) ->
            results.should.eql(['12', '11'])
            done()

  describe 'Amico#reciprocated', ->
    it 'should return the correct list', (done) ->
      Amico.follow 1, 11, ->
        Amico.follow 11, 1, ->
          Amico.follow 1, 12, ->
            Amico.follow 12, 1, ->
              Amico.reciprocated 1, (results) ->
                results.should.eql(['12', '11'])
                done()

  describe 'Amico#followingCount', ->
    it 'should return the correct count', (done) ->
      Amico.follow 1, 11, ->
        Amico.followingCount 1, (count) ->
          count.should.eql(1)
          done()

  describe 'Amico#followersCount', ->
    it 'should return the correct count', (done) ->
      Amico.follow 1, 11, ->
        Amico.followersCount 11, (count) ->
          count.should.eql(1)
          done()

  describe 'Amico#reciprocatedCount', ->
    it 'should return the correct count', (done) ->
      Amico.follow 1, 11, ->
        Amico.follow 11, 1, ->
          Amico.reciprocatedCount 1, (count) ->
            count.should.eql(1)
            done()

  describe 'Amico#blockedCount', ->
    it 'should return the correct count', (done) ->
      Amico.block 1, 11, ->
        Amico.blockedCount 1, (count) ->
          count.should.eql(1)
          done()

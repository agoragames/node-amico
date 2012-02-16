# Node-Amico ![Build Status](https://secure.travis-ci.org/agoragames/node-amico.png)](https://secure.travis-ci.org/agoragames/node-amico.png)

This is a NodeJS port of [amico](https://github.com/agoragames/amico) using CoffeeScript.

## Differences

All commands have been ported over, with the addition of a callback for anything that
calls redis.

## Development

This project uses a Makefile to help with development tasks. The following functions
are provided:

* `make test`: Generates teh JS from the `src` dir, then runs [jessie](https://github.com/futuresimple/jessie).
* `make generate-js`: Generates the JS from the `src` dir to the `lib` dir
* `make remove-js`: Deletes the JS from the `lib` dir
* `make publish`: Generates the JS, publishes to NPM, then deletes the JS
* `make link`: Local link of the package to test before publishing to NPM

Take a look at `src/spec_helper.js` for some commands to assist in async testing.

## Author

Written by [Andrew Nordman](https://github.com/cadwallion), based on 
[David Czarnecki](https://github.com/czarneckid)'s [amico](https://github.com/agoragames/amico).


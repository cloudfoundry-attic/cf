# Release Notes

## Summary

## Changes

* SHA: [9a9f7a37ebffea8317044e37f89f19a53fb531b8](git@github.com:cloudfoundry/cf/commit/9a9f7a37ebffea8317044e37f89f19a53fb531b8)
    * bump cfoundry and add pended specs
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* SHA: [4b1003aa662de28584662aaaa081f7522235d7d4](git@github.com:cloudfoundry/cf/commit/4b1003aa662de28584662aaaa081f7522235d7d4)
    * Allow binding to a user-provided service instance

* Feature test for binding
* Added env app, which we'll use to show credentials
* Ensure we're in a space when running the 'cf services' command
[#53735407](http://www.pivotaltracker.com/story/53735407)
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* SHA: [2fa817f7e7678d098d9167da242c7114205e5c99](git@github.com:cloudfoundry/cf/commit/2fa817f7e7678d098d9167da242c7114205e5c99)
    * Add test for listing services, bump cfoundry
    * David Sabeti and Ryan Tang, pair+dsabeti+ryantang@pivotallabs.com


* SHA: [f98fd2b821eb923b2437f8d31eec10ac93069891](git@github.com:cloudfoundry/cf/commit/f98fd2b821eb923b2437f8d31eec10ac93069891)
    * User can create user-provided service instances
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


* SHA: [8dce04fe9390f75a9b836ccec8a87546701eff05](git@github.com:cloudfoundry/cf/commit/8dce04fe9390f75a9b836ccec8a87546701eff05)
    * Remove false expectation in integration test

The backend has been optimized to start the first instance immmediately, so we should not expect to see '0 of 1' in the output
    * David Sabeti and Ryan Tang, pair+dsabeti+ryantang@pivotallabs.com


* SHA: [299994d56b44bf6e8142a34a21d4cbed0c6cc8ae](git@github.com:cloudfoundry/cf/commit/299994d56b44bf6e8142a34a21d4cbed0c6cc8ae)
    * Add more expectation helpers
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


* SHA: [cfa13c68dd6cbfbf1de6ae7f5ad11ed2589ee589](git@github.com:cloudfoundry/cf/commit/cfa13c68dd6cbfbf1de6ae7f5ad11ed2589ee589)
    * simple has_label matcher
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


* SHA: [aa329edad6270a5da1a3841db169dfe0b97c03b7](git@github.com:cloudfoundry/cf/commit/aa329edad6270a5da1a3841db169dfe0b97c03b7)
    * Remove dead code
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


------

_Release Notes generated with [Anchorman](http://github.com/infews/anchorman)_
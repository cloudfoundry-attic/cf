# Release Notes

## Summary

## Changes

* Include anchorman as development dependency.
    * SHA: 319570b4b61190add2b58add49229cb0d30e0e8d
    * Corbin Halliwill and Matthew Horan, pair+challiwill+mhoran@pivotallabs.com


* Move delete oprphaned service spec to features dir
    * SHA: 83fda583c1a57fe3c87ef8e24a58a48e568b584c
    * Corbin Halliwill and Matthew Horan, pair+challiwill+mhoran@pivotallabs.com


* Change prompt for creating user provided services

[#54220106](http://www.pivotaltracker.com/story/54220106)
    * SHA: 3dc3573e5acb3a469a11e3764f0e14bbaf635355
    * David Julia and Ryan Tang, pair+djulia+ryantang@pivotallabs.com


* Add service broker command for admin.
    * SHA: 92f2fa03abc7bda71c7826c4ba374c49d69cf931
    * Corbin Halliwill and Matthew Horan, pair+challiwill+mhoran@pivotallabs.com


* Set up component runner for cf
    * SHA: 3a67ebd37c766b2d16bda9bb9317aa35cc74d02e
    * Corbin Halliwill and Matthew Horan, pair+challiwill+mhoran@pivotallabs.com


* Move push flow spec to spec/features
    * SHA: 42bff8757311a7997e113e0642063d600871f801
    * Corbin Halliwill and Matthew Horan, pair+challiwill+mhoran@pivotallabs.com


* Bump cfoundry

Also, update cf.dev to include ruby < 1.9.3 warning
    * SHA: 44ee71989691c4757b45bad83bb27443d050afdc
    * David Sabeti and Jeff Schnitzer, pair+dsabeti+jschnitzer@pivotallabs.com


* Merge remote-tracking branch origin/proxy_support

Conflicts:
	cf.gemspec
    * SHA: 8f5b800ea82518cf9c16187384d176b58fedbfb1
    * David Sabeti and Jeff Schnitzer, pair+dsabeti+jschnitzer@pivotallabs.com


* bump version to 5.0.0.rc2
    * SHA: 2d50d0d780c3ade676df22b0f8d62c2b0237a3d9
    * Jesse Zhang and Jimmy Da, pair+jz+jda@pivotallabs.com


* only ignore the root level Gemfile.lock

this also fixes integration test for CI
    * SHA: 471d0f36249c34c962b055bb1738c34fdae93337
    * Jesse Zhang and Jimmy Da, pair+jz+jda@pivotallabs.com


* Merge branch 'service_connector' of github.com:cloudfoundry/cf

Conflicts:
	lib/cf/version.rb
    * SHA: 4605b98b774107b05aac0c9e1d5ea0bada098383
    * Jesse Zhang and Jimmy Da, pair+jz+jda@pivotallabs.com


* make sure there is no manifest before push flow test
    * SHA: 78ec8b523f533bd0687bb4aca8a8a68509a7387f
    * Jesse Zhang and Jimmy Da, pair+jz+jda@pivotallabs.com


* integration test for deleting app with bound user-provided service
    * SHA: 20e7b9d3dee14316642ef726674ca23405eafba4
    * Jesse Zhang and Jimmy Da, pair+jz+jda@pivotallabs.com


* Add patch number to .ruby-version for rbenv compatibility
    * SHA: 2dbb2099997e6853693663276a7b6c84c2ad8442
    * Amit Gupta and John Foley, pair+agupta+jfoley@pivotallabs.com


* Bumping to version 4.2.9.rc5.
    * SHA: e99cef5cf8ffd0f8fe475b81be387b49d2f9b597
    * Jeff Schnitzer and Jesse Zhang, pair+jschnitzer+jz@pivotallabs.com


* clean up the user-provided service after push flow integration tests
    * SHA: a03410fa7df3c771b0402f8b45e2e21cf504fe88
    * Jeff Schnitzer and Jesse Zhang, pair+jschnitzer+jz@pivotallabs.com


* User can save and use a manifest with user-provided services

[#53737911](http://www.pivotaltracker.com/story/53737911)
    * SHA: 469d07e99896c71f3dfb4ca4acbb8e3025bf74b0
    * Jeff Schnitzer and Jesse Zhang, pair+jschnitzer+jz@pivotallabs.com


* integration test for push with manifest
    * SHA: 4893858946b86aac85bf4c992195d079db89dd5c
    * Jeff Schnitzer and Jesse Zhang, pair+jschnitzer+jz@pivotallabs.com


* has_label usable as argument matcher
    * SHA: b775fe76017952a0c7eac2742305469a70d09ef5
    * Jeff Schnitzer and Jesse Zhang, pair+jschnitzer+jz@pivotallabs.com


* clean up test
    * SHA: 9775741100b53ec1398a433d6026660f1fb82ba0
    * Jesse Zhang and Will Read, pair+jz+will@pivotallabs.com


* save user-provided service instance to manifest during push
    * SHA: a7ebef4a57543e3dbbe7c57049f319f89cbf6984
    * Jesse Zhang and Will Read, pair+jz+will@pivotallabs.com


* unbreak writing manifest during push
    * SHA: 40f540c01d7248db389aba200ba9816c908006fb
    * Jesse Zhang and Will Read, pair+jz+will@pivotallabs.com


* descriptive variable names
    * SHA: 5ea758def44b693630a74587ef2b8b186eae841e
    * Jesse Zhang and Will Read, pair+jz+will@pivotallabs.com


* Bumping to version 4.2.9.rc3.
    * SHA: 7a0ebcc8ca62df1de639ece4d60a1eff4bd15c1e
    * Jesse Zhang and Will Read, pair+jz+will@pivotallabs.com


* user can create and bind user provided service during push

[finishes #53725823](http://www.pivotaltracker.com/story/53725823)
    * SHA: eb7bc2e8092572c80c7adda59d761b1af223461e
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


* [#53920639](http://www.pivotaltracker.com/story/53920639) Use proxy options when connecting to UAA/Login servers
    * SHA: f5d28ba8003f38e5b50fca5c85f4aac2a724a887
    * Joseph Palermo and Will Read, pair+joseph+will@pivotallabs.com


* User can create/bind user-provided services during 'cf push'.

Most code irons out bugs in 'cf services', by using update CFoundry models.

[finishes #53725823](http://www.pivotaltracker.com/story/53725823)
    * SHA: e7d2ed191b6f5f331d28fc7cb974e519143714a3
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


* Update credential help prompt
    * SHA: 23dbe28c537f8c126ee18addeb140e17f8c90bf3
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Bumping to version 4.2.9.rc2.
    * SHA: d26c916a3fd2690695e45e43113a9c2b4431394a
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Exercise delete user-provisioned service instances, clean up after specs
[Finishes #53735423](http://www.pivotaltracker.com/story/53735423)
    * SHA: 26748affaa44c010247f615e3d0d28c3b1159b39
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Merge branch 'master' into service_connector

Conflicts:
	cf.gemspec
	lib/cf/version.rb
    * SHA: 0652a3b4ce7a77aa6417bd025b264a993d0e087b
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Prompt for all keys at once [Finishes #54220106](http://www.pivotaltracker.com/story/54220106)
    * SHA: 9e2aa45562f30d3176c85dbd34daa6cd0dd906e4
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Fix broken spec
    * SHA: 30ecbc8f0b4dc39c2a52e137cf1f21286f50f556
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Bumping to version 4.2.8.rc2.
    * SHA: 13efe17f02667561633635bdea2caf9368cc520e
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* User-provided services appear as such in the table
    * SHA: bfb6263c7d6c7fac8ec28ba76a4b40c9533fe525
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Test bind and unbind user-provided services
    * SHA: 072b0ecdc2e9ec1dd557bc1817458a73317b584c
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Updated services_spec
    * SHA: 8b948a59e8e393490b488c676aef8f80400792e2
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* Bumping to version 4.2.8.rc1.
    * SHA: 9b67e4a7a050aeb36c067111ecf4a1dad92bc806
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* bump cfoundry and add pended specs
    * SHA: 9a9f7a37ebffea8317044e37f89f19a53fb531b8
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* Allow binding to a user-provided service instance

* Feature test for binding
* Added env app, which we'll use to show credentials
* Ensure we're in a space when running the 'cf services' command
[#53735407](http://www.pivotaltracker.com/story/53735407)
    * SHA: 4b1003aa662de28584662aaaa081f7522235d7d4
    * Ryan Tang and Will Read, pair+ryantang+will@pivotallabs.com


* Add test for listing services, bump cfoundry
    * SHA: 2fa817f7e7678d098d9167da242c7114205e5c99
    * David Sabeti and Ryan Tang, pair+dsabeti+ryantang@pivotallabs.com


* User can create user-provided service instances
    * SHA: f98fd2b821eb923b2437f8d31eec10ac93069891
    * David Sabeti and Jesse Zhang, pair+dsabeti+jz@pivotallabs.com


------

_Release Notes generated with _[Anchorman](http://github.com/infews/anchorman)_
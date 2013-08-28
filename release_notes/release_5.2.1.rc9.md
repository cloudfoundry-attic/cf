# Release Notes

## Summary

## Changes

* default to https instead of using TCP to check protocol
    * SHA: 448190fa53c96e9ee1726a7b75856c695c1e2b5f
    * David Sabeti and George Dean, pair+dsabeti+gdean@pivotallabs.com


* Do not attempt to populate a space if there are no orgs.

  Attempting to populate a space  was causing cf to crash
  when trying to login to cloud foundry deployments that had
  no orgs.

  +Also cleaned up the specs around the Target Populator to make it
  clear that an Organization Populator returns a CFoundry Organization.

  [Fixes #55842402](http://www.pivotaltracker.com/story/55842402)
    * SHA: f3faeae3df0469793893cc22aa7c977564589d10
    * David Julia and Jimmy Da, pair+djulia+jda@pivotallabs.com


* Windows RubyInstaller expects the secure URL.

Add notes to windows:build task for setup [#55762614](http://www.pivotaltracker.com/story/55762614)
    * SHA: a2419179e9cbb2eb50ab31a0322299294cb1f863
    * George Dean and Will Read, pair+gdean+will@pivotallabs.com


* Package the cf CLI to run on Windows

[#55762614](http://www.pivotaltracker.com/story/55762614)
    * SHA: 180e58bcadfb89e6da7992d15bc179e77000bcf4
    * George Dean and Will Read, pair+gdean+will@pivotallabs.com


------

_Release Notes generated with _[Anchorman](http://github.com/infews/anchorman)_
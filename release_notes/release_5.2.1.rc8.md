# Release Notes

## Summary

## Changes

* remove redundant call to sane_target_url
    * SHA: 7ae4463dc018973c7a74f7201d0ae9920b1f701c
    * David Sabeti, pair+dsabeti@pivotallabs.com


* Refactor sane_target_url
    * SHA: 78251b74f1dc63f2d7215eabc9ebf69889e1ae7b
    * David Sabeti, pair+dsabeti@pivotallabs.com


* sane_target_url catches ETIMEDOUT thrown by TCP connection
    * SHA: d8d181448cecc1d72fa04f57683f3772e74a2fd5
    * David Sabeti, pair+dsabeti@pivotallabs.com


* Add explicit timeout to sane_target_url

Plus, backfilling tests
    * SHA: e07babcc4b5a025a212a0a89c955dbc756749bd0
    * David Sabeti, pair+dsabeti@pivotallabs.com


* Remove default api url
    * SHA: e418d1e7c59e930c0fb2fe399d25f9be6432ae07
    * David Sabeti, pair+dsabeti@pivotallabs.com


* Merge pull request #57 from jbayer/master

fixed mispelling in proxy help
    * SHA: a5db80758724f1f36f5dc01cf30c0a73f66a24fc
    * Ryan Tang, ryantang@gmail.com


* fixed mispelling in proxy help
    * SHA: 502a4525f759a1b2161079a673a024a2b6a3f1c9
    * James Bayer, jambay@yahoo.com


* Handle services which have no version or provider

Extracted service presenter and used for service instance presentation.
Ensure that factoried service instances and service plans have services.

[Finishes #54129477](http://www.pivotaltracker.com/story/54129477)
    * SHA: f4a76e0f53cf856f355cea769307a0b6c577432f
    * Alex Choi and Matthew Horan, pair+alex+mhoran@pivotallabs.com


* "Unknown service_broker" -> "Unknown service broker"
    * SHA: f4f20fd4e4a176694ed57f204fe81b8303140043
    * Ian Lesperance and Jeff Schnitzer, pair+ilesperance+jschnitzer@pivotallabs.com


* Service broker update now provides default values.

[Finishes #55753254](http://www.pivotaltracker.com/story/55753254)
    * SHA: c10bf2e8b930f5223fe2481f53bd9e40766bfda8
    * Jeff Schnitzer and Jimmy Da, pair+jschnitzer+jda@pivotallabs.com


* Ensure everyone develops on the same gem versions
    * SHA: 59a2f2942a1489c1bc92f63775f0088559005b4c
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Relaxed unnecessarily strict gem requirements
    * SHA: 5d9e1fbe04e318f012f0ad172074d7453013a8c3
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


* Prompt to confirm version before releasing gem
    * SHA: ed1f711a03d08e63c817fd71a715f11e2011b93b
    * Aaron Levine and Joseph Palermo, pair+aaron+joseph@pivotallabs.com


* Re-enable release notes

Anchorman no longer depends on the Github Markdown gem, which was
causing issues on Travis.
    * SHA: 3e6e3677074c1a71e8c63117d32d2ec8036b9eaa
    * Ian Lesperance and Will Read, pair+ilesperance+will@pivotallabs.com


------

_Release Notes generated with _[Anchorman](http://github.com/infews/anchorman)_
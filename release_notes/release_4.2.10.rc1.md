# Release Notes

## Summary

## Changes

* Remove --all option from cf help. cf help now shows all commands by default.
[finishes #53934033](http://www.pivotaltracker.com/story/53934033)
    * SHA: 458b7a6c912e56fa8d7b74449bc4e01f70ad6229
    * Alan Moran and Joseph Palermo, pair+bonzofenix+joseph@pivotallabs.com


* Temporarily remove anchorman dependency

It depends on github-markdown, which must be built with native extensions, which is not supported on Travis.
    * SHA: 43574500708898b68841bb390316af09408c2236
    * George Dean and Joseph Palermo, pair+gdean+joseph@pivotallabs.com


------

_Release Notes generated with _[Anchorman](http://github.com/infews/anchorman)_
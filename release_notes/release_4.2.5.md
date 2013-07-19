# Release Notes

## Summary

## Changes

* SHA: [c2db88ae2cbc38716ea5458828fb8a5264af2d01](git@github.com:cloudfoundr/commit/c2db88ae2cbc38716ea5458828fb8a5264af2d01)
    * Merge branch 'master' into apps_from_manifests_for_plugins
    * Andreas Maier and Corbin Halliwill, pair+amaier+challi@pivotallabs.com


* SHA: [690c6205bacb543ddd3689c43a8ad3f92280c901](git@github.com:cloudfoundr/commit/690c6205bacb543ddd3689c43a8ad3f92280c901)
    * Make console command able to use manifest to determine app

* had to load plugin/manifest first so that dependent plugins can use it

Signed-off-by: Glenn Oppegard <goppegard@pivotallabs.com>
    * Stephan Hagemann, stephan@pivotallabs.com


* SHA: [07f1f8c5c3862fe5b0538ddcdf98c1786eb36c0a](git@github.com:cloudfoundr/commit/07f1f8c5c3862fe5b0538ddcdf98c1786eb36c0a)
    * Remove outdated README

Signed-off-by: Glenn Oppegard <goppegard@pivotallabs.com>
    * Stephan Hagemann, stephan@pivotallabs.com


* SHA: [15dcd698d9fdfe1e74d6dd15b0232e88b3d2bbf4](git@github.com:cloudfoundr/commit/15dcd698d9fdfe1e74d6dd15b0232e88b3d2bbf4)
    * Allow plugins to use manifest.yml to infer the current app

* move manifest argument logic into default_to_app_from_manifest method
* added 'fail_without_app' flag allow plugins to handle no-app case themselves

Signed-off-by: Glenn Oppegard <goppegard@pivotallabs.com>
    * Stephan Hagemann, stephan@pivotallabs.com


------

_Release Notes generated with [Anchorman](http://github.com/infews/anchorman)_
# Release Notes

## Summary

## Changes

* SHA: [b41e0cee6adce1fdd58c72f21c236a9316cfae1b](git@github.com:cloudfoundry/cf/commit/b41e0cee6adce1fdd58c72f21c236a9316cfae1b)
    * Fix specs related to merge that changes create-space output
    * Andreas Maier and Joseph Palermo, pair+amaier+joseph@pivotallabs.com


* SHA: [25e5b758187b1b9823a7290e9ef78a1b6e2ba2ad](git@github.com:cloudfoundry/cf/commit/25e5b758187b1b9823a7290e9ef78a1b6e2ba2ad)
    * Merge remote-tracking branch 'origin/pr/11'
    * Andreas Maier and Joseph Palermo, pair+amaier+joseph@pivotallabs.com


* SHA: [31c851ed1c2d0bda6dd22ac92471f1999eb2b124](git@github.com:cloudfoundry/cf/commit/31c851ed1c2d0bda6dd22ac92471f1999eb2b124)
    * Display next command on new line

This allows for triple-click to select the whole line for
easy copy/paste into terminal.

Usage:

    $ bundle exec bin/cf.dev create-space
    Name> test5

    Creating space test5... OK
    Adding you as a manager... OK
    Adding you as a developer... OK
    Space created!

    cf switch-space test5    # targets new space
    * Dr Nic Williams, drnicwilliams@gmail.com


------

_Release Notes generated with [Anchorman](http://github.com/infews/anchorman)_
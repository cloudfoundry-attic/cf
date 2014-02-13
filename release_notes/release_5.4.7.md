# Release Notes

## Summary

## Changes

* calculate cpu usage percentage correctly in 'cf stats'

- value returned from cloud controller was already a percentage, thus we
  needed to multiply by 100 in order to handle correclty.
    * SHA: 99c29cd22db209a6742864504946e847e94e890e
    * James Myers, pair+jmyers@pivotallabs.com


------

_Release Notes generated with _[Anchorman](http://github.com/infews/anchorman)_
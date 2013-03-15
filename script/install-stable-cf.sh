#!/bin/sh

SCRIPTDIR=$(dirname $0)
CFDIR=$(dirname $SCRIPTDIR)

set -e

pushd $CFDIR

git fetch --tags
git checkout latest-staging

gem uninstall cf --all --ignore-dependencies --executables

rm -f cf-*.gem
gem build cf.gemspec

popd

gem install $CFDIR/cf-*.gem

gem uninstall cfoundry --all --ignore-dependencies --executables

git clone git://github.com/cloudfoundry/cf-lib.git cf-lib-tmp
# TODO: checkout latest-cf?
pushd cf-lib-tmp
gem build cfoundry.gemspec
gem install cfoundry-*.gem
popd
rm -rf cf-lib-tmp

git clone git://github.com/cloudfoundry/cf-plugins.git cf-plugins-tmp
pushd cf-plugins-tmp
for plugin in manifests console tunnel mcf admin; do
  pushd $plugin
  gem uninstall $plugin-cf-plugin --all --ignore-dependencies --executables
  gem build $plugin-cf-plugin.gemspec
  gem install $plugin-cf-plugin-*.gem
  popd
done
popd
rm -rf cf-plugins-tmp

cf -v

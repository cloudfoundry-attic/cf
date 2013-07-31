# cf - Cloud Foundry Command Line Interface

[![Build Status](https://travis-ci.org/cloudfoundry/cf.png)](https://travis-ci.org/cloudfoundry/cf)
[![Gem Version](https://badge.fury.io/rb/cf.png)](http://badge.fury.io/rb/cf) 
[![Code Climate](https://codeclimate.com/github/cloudfoundry/cf.png)](https://codeclimate.com/github/cloudfoundry/cf)

The Cloud Foundry CLI has been completely rewritten. Installation, usage & contribution instructions are below.

This tool requires cloud_controller_ng. It is not compatible with cloud_controller v1.

## Requirements

cf should work with Ruby 1.9.x and newer.

## Installation

```
$ gem install cf
```

## Development

```
$ git clone git@github.com:cloudfoundry/cf.git
$ cd cf
$ bundle install
```

To run the specs:

```
$ bundle exec rake
```

To run the checked out code use the cf.dev script:

```
./bin/cf.dev 
```

## Usage
See the 'cf help' command for up-to-date usage info:

```
$ cf help
```

# Cloud Foundry Resources #

_Cloud Foundry Open Source Platform as a Service_

## Learn

Our documentation, currently a work in progress, is available here: [http://cloudfoundry.github.com/](http://cloudfoundry.github.com/)

## Ask Questions

Questions about the Cloud Foundry Open Source Project can be directed to our Google Groups.

* BOSH Developers: [https://groups.google.com/a/cloudfoundry.org/group/bosh-dev/topics](https://groups.google.com/a/cloudfoundry.org/group/bosh-dev/topics)
* BOSH Users:[https://groups.google.com/a/cloudfoundry.org/group/bosh-users/topics](https://groups.google.com/a/cloudfoundry.org/group/bosh-users/topics)
* VCAP (Cloud Foundry) Developers: [https://groups.google.com/a/cloudfoundry.org/group/vcap-dev/topics](https://groups.google.com/a/cloudfoundry.org/group/vcap-dev/topics)

## File a bug

Bugs can be filed using Github Issues within the various repositories of the [Cloud Foundry](http://github.com/cloudfoundry) components.

## OSS Contributions

The Cloud Foundry team uses GitHub and accepts contributions via [pull request](https://help.github.com/articles/using-pull-requests)

Follow these steps to make a contribution to any of our open source repositories:

1. Complete our CLA Agreement for [individuals](http://www.cloudfoundry.org/individualcontribution.pdf) or [corporations](http://www.cloudfoundry.org/corpcontribution.pdf)
2. Set your name and email

```
$ git config --global user.name "Firstname Lastname"
$ git config --global user.email "your_email@youremail.com"
```

3. Fork the repo
4. Make your changes on a topic branch, commit, and push to github and open a pull request.

Once your commits are approved by Travis CI and reviewed by the core team, they will be merged.

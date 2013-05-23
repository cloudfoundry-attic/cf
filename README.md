# cf - CLI for Cloud Foundry

[![Build Status](https://travis-ci.org/cloudfoundry/cf.png)](https://travis-ci.org/cloudfoundry/cf)
[![Gem Version](https://badge.fury.io/rb/cf.png)](http://badge.fury.io/rb/cf)
[![Code Climate](https://codeclimate.com/github/cloudfoundry/cf.png)](https://codeclimate.com/github/cloudfoundry/cf)

The CLI for Cloud Foundry is being completely rewritten. Installation, usage & contribution instructions are below.

This tool requires cloud_controller_ng. It is not compatible with cloud_controller v1.

## Installation

```
$ gem install cf
```

## Development

```
$ git clone git@github.com:cloudfoundry/cf.git
$ cd cf
$ bundle install
$ rake gem:install
```

## Usage

```
$ cf help --all
Getting Started
  colors       	Show color configuration
  info         	Display information on the current target, user, etc.
  login [EMAIL]	Authenticate with the target
  logout       	Log out from the target
  target [URL] 	Set or display the target cloud, organization, and space
  targets      	List known targets.

Applications
  app [APP]	Show app information
  apps     	List your applications

  Management
    delete APPS...     	Delete an application
    push [NAME]        	Push an application, syncing changes if it exists
    rename [APP] [NAME]	Rename an application
    restart APPS...    	Stop and start an application
    start APPS...      	Start an application
    stop APPS...       	Stop an application
    console APP        	Open a console connected to your app

  Information
    crashes APPS...         	List an app's crashed instances
    env [APP]               	Show all environment variables set for an app
    set-env APP NAME [VALUE]	Set an environment variable
    unset-env APP NAME      	Remove an environment variable
    file APP [PATH]         	Print out an app's file contents
    files APP [PATH]        	Examine an app's files
    tail APP [PATH]         	Stream an app's file contents
    health APPS...          	Get application health
    instances APPS...       	List an app's instances
    logs [APP]              	Print out an app's logs
    crashlogs APP           	Print out the logs for an app's crashed instances
    scale [APP]             	Update the instances/memory limit for an application
    stats [APP]             	Display application instance status
    map [APP] [HOST] DOMAIN 	Add a URL mapping
    unmap [URL] [APP]       	Remove a URL mapping

Services
  service SERVICE	Show service information
  services       	List your services

  Management
    bind-service [SERVICE] [APP]    	Bind a service to an application
    create-service [OFFERING] [NAME]	Create a service
    delete-service [SERVICE]        	Delete a service
    rename-service [SERVICE] [NAME] 	Rename a service
    unbind-service [SERVICE] [APP]  	Unbind a service from an application
    tunnel [INSTANCE] [CLIENT]      	Create a local tunnel to a service.

Organizations
  create-org [NAME]               	Create an organization
  delete-org [ORGANIZATION]       	Delete an organization
  org [ORGANIZATION]              	Show organization information
  orgs                            	List available organizations
  rename-org [ORGANIZATION] [NAME]	Rename an organization

Spaces
  create-space [NAME] [ORGANIZATION]	Create a space in an organization
  delete-space SPACES...            	Delete a space and its contents
  rename-space [SPACE] [NAME]       	Rename a space
  space [SPACE]                     	Show space information
  spaces [ORGANIZATION]             	List spaces in an organization
  switch-space NAME                 	Switch to a space

Routes
  routes	List routes in a space

Domains
  domains [SPACE]    	List domains in a space
  map-domain NAME    	Map a domain to an organization or space
  unmap-domain DOMAIN	Unmap a domain from an organization or space

Administration
  users                                         	List all users
  curl MODE PATH HEADERS...                     	Execute a raw request
  guid TYPE [NAME]                              	Obtain guid of an object(s)
  service-auth-tokens                           	List service auth tokens
  create-service-auth-token [LABEL] [PROVIDER]  	Create a service auth token
  update-service-auth-token [SERVICE_AUTH_TOKEN]	Update a service auth token
  delete-service-auth-token [SERVICE_AUTH_TOKEN]	Delete a service auth token

  User Management
    create-user [EMAIL]	Create a user
    passwd             	Update the current user's password
    register [EMAIL]   	Create a user and log in

Micro Cloud Foundry
  micro-status VMX [PASSWORD] 	Display Micro Cloud Foundry VM status
  micro-offline VMX [PASSWORD]	Micro Cloud Foundry offline mode
  micro-online VMX [PASSWORD] 	Micro Cloud Foundry online mode

Options:
      --[no-]color                 Use colorful output
      --[no-]script                Shortcut for --quiet and --force
      --debug                      Print full stack trace (instead of crash log)
      --http-proxy HTTP_PROXY      Connect though an http proxy server
      --https-proxy HTTPS_PROXY    Connect though an https proxy server
  -V, --verbose                    Print extra information
  -f, --[no-]force                 Skip interaction when possible
  -h, --help                       Show command usage
  -m, --manifest FILE              Path to manifest file to use
  -q, --[no-]quiet                 Simplify output format
  -t, --trace                      Show API traffic
  -v, --version                    Print version number
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

    git config --global user.name "Firstname Lastname"
    git config --global user.email "your_email@youremail.com"

3. Fork the repo
4. Make your changes on a topic branch, commit, and push to github and open a pull request.

Once your commits are approved by Travis CI and reviewed by the core team, they will be merged.

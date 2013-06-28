[![Build Status](https://travis-ci.org/cloudfoundry/micro-cf-plugin.png)](https://travis-ci.org/cloudfoundry/micro-cf-plugin)
[![Gem Version](https://badge.fury.io/rb/micro-cf-plugin.png)](http://badge.fury.io/rb/micro-cf-plugin)

## Micro Cloud Foundry
### Info
This plugin allows you to manage your Micro Cloud Foundry VM.

### Installation

If you have installed CF via gem install, use:
```
gem install micro-cf-plugin
```

If you have installed CF through bundler and the Gemfile, add the following to your Gemfile:
```
gem "micro-cf-plugin"
```

### Usage
```
micro-status VMX [PASSWORD]   Display Micro Cloud Foundry VM status
micro-offline VMX [PASSWORD]	Micro Cloud Foundry offline mode
micro-online VMX [PASSWORD] 	Micro Cloud Foundry online mode
```

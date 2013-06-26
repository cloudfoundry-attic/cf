[![Build Status](https://travis-ci.org/cloudfoundry/admin-cf-plugin.png)](https://travis-ci.org/cloudfoundry/admin-cf-plugin)
[![Gem Version](https://badge.fury.io/rb/admin-cf-plugin.png)](http://badge.fury.io/rb/admin-cf-plugin)

## Admin
### Info
This plugin allows you to make manual HTTP requests to the Cloud Foundry REST API.

### Installation

If you have installed CF via gem install, use:
```
gem install admin-cf-plugin
```

If you have installed CF through bundler and the Gemfile, add the following to your Gemfile:
```
gem "admin-cf-plugin"
```

### Usage

```
curl MODE PATH HEADERS...                       Execute a raw request
guid TYPE [NAME]                                Obtain guid of an object(s)
set-quota [QUOTA_DEFINITION] [ORGANIZATION]     Change the quota definition for the given (or current) organization.
service-auth-tokens                           	List service auth tokens
create-service-auth-token [LABEL] [PROVIDER]  	Create a service auth token
update-service-auth-token [SERVICE_AUTH_TOKEN]	Update a service auth token
delete-service-auth-token [SERVICE_AUTH_TOKEN]	Delete a service auth token
```

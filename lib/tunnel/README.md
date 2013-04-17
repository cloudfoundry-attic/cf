[![Build Status](https://travis-ci.org/cloudfoundry/tunnel-cf-plugin.png)](https://travis-ci.org/cloudfoundry/tunnel-cf-plugin)
[![Gem Version](https://badge.fury.io/rb/tunnel-cf-plugin.png)](http://badge.fury.io/rb/tunnel-cf-plugin)

## Tunnel
### Info
This plugin allows you to connect to a Cloud Foundry service using your own command line client. By default, the plugin supports *redis*, *mysql*, *mongodb*, and *postgresql*.

### Installation
```
gem install tunnel-cf-plugin
```

### Usage
```
tunnel [INSTANCE] [CLIENT]        Create a local tunnel to a service.
```

You can add support for other command-line clients by providing a `~/.cf/clients.yml` file with the following format:

```yaml
service_name:
  client_program_name: command line arguments
  client_program_name_2:
    command: command line arguments
    environment:
      - ENV_VAR_NAME=env_var_value
```



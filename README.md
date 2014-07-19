# Zabbix Useragent Library

## Introduction

This software is intended to simplify the development and deployment of scripts and processes used as 'useragents' by the zabbix agent.

## How it Works

The idea is that each different thing to monitor is a perl script that defines a module under the Monitoring::Plugins namespace.  It will then get automatically included using Modules::Pluggable.  When developing a plugin, all that is required is the definition of at least a 'register' function and a 'test' function.

The 'register' function should evaluate the system to first establish if the plugin is applicable or not, and if it is, it should return an array of strings for be included as UserAgent settings to go in the zabbix agent 
configuration.  This should look like:

```
zabbix.item.key,monitoring.pl -m <modulename> -a test [--args <args list>]
```

You could cron the run of the register process so that new plugins are added to zabbix periodically.

The 'test' function is the function that actually determines the value for the key that will be sent back to Zabbix as the value for the item which will be used to determine any alarm states.  It is used when '-a test' argument is specified with a '-m modulename'.

An optional 'discover' function can be specified.  This is used when using low level discovery within zabbix.  For example, if you want to set up SMART monitoring of disks, you first want to know what disks there are.  A discover function will find the disks that should have SMART monitoring enabled.  Zabbix expects JSON to be returned.  The discover function within the module should just return a hash, the process will convert it to JSON output.  See the Zabbix manual on low level discovery for more info on the structure of the hash.

If using a discover function, you will have to ensure that the register function includes it in its return.

## An Example

See the Smartd.pm as an example.  It defines all three functions.

The register function ensures that the required executable exists and that the suid bit is set (so the zabbix process can use it, and access the disk devices).  If the executable is not available, then this module is not applicable and thus returns nothing.  If it does, it registers the following user agents in array like:

```
[
  'smartd.dev.discover,monitoring.pl -m Smartd -a discover',
  'smartd.dev.health[*],monitoring.pl -m Smartd -a test --args $1',
];
```

This registers a discovery agent as well as a test agent that accepts an argument that will be the device to check.  The discovery agent is configured in Zabbix for low level discovery to determine the devices with the test agent will be called for.

The discovery function looks for any SMART enabled devices that can be monitored for a SMART status.  It returns a hash that looks like:

```
{
  'data' => [
    {
      '{#DEVNAME}' => '/dev/sda'
    },
    {
      '{#DEVNAME}' => '/dev/sdb'
    },
  ]
}
```

The return hash must contain a 'data' key, the value for which must be an array of hashes.  Each hash defines one item to be monitored the keys should be in the form of '{#KEY}' which becomes a macro available in the item templates.

See the low level discovery parts in the Zabbix manual for more.

The test function in this case recieves a device as an argument.  It uses this to run the appropriate smartctl command.  It parses the output to determine the SMART state of the device with is returned as a string which is then passed back to Zabbix.

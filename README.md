# Dynamic inventory

## Build invetory for alm ansible projects
To generate all ofa inventories use the script `build_inventory.sh`

## Setting the environment
The python virtual env must contain `request` module

## Examples

### Getting Help
```shell
./lookup_bmc.py --help

usage: lookup_bmc.py [-h] (-d DATABASE | -s SERVERNAME | -p SERVER_PATTERN) [-g GROUP_NAME]

Query database or servername.

options:
  -h, --help            show this help message and exit
  -d DATABASE, --database DATABASE
                        Get the server for the given database.
  -s SERVERNAME, --servername SERVERNAME
                        Get databases on given server.
  -p SERVER_PATTERN, --server_pattern SERVER_PATTERN
                        List all server matching
  -g GROUP_NAME, --group_name GROUP_NAME
                        List all server matching
```

#### Getting the server for a database
```shell
./lookup_bmc.py -d TAPEV3

Servername for 'TAPEV3': lxsgvatapevx16p.corp.ubp.ch
```

#### Getting all database on a server
```shell
 ./lookup_bmc.py -s lxsgvatapevx16p.corp.ubp.ch
Databases for 'lxsgvatapevx16p.corp.ubp.ch'
  - TAPEV1
  - TAPEV4
  - TAPEV3
  - tapev2_02
```

#### Generate an yaml inventory for all GVA and EV5 
```shell
./lookup_bmc.py -p '.*gva.*ev5.*' -g ora_ev5

ora_ev5:
  hosts:
    lxvgvabusev501p:
    axvgvaoraev501p:
    lxvgvaoraev501p:
```
**TIP**: you can use regexp patterns in `-p` option

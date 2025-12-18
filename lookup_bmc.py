#!/usr/bin/env python3
import requests
import argparse
import re
import urllib3
RED = "\033[31m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RESET = "\033[0m"

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)


def fetch_data(database_name=None, server_name=None):
    base_url = 'https://addm/api/v1.13/data/search?'

    # query = (
    #    'query=SEARCH%20Database%20WHERE%20type%20HAS%20SUBWORD%20%27'
    #    'Oracle%27%20SHOW%20name%2C%20%20%20%20%20%20%23Detail%3ADetail%3AElementWithDetail%3A'
    #    'SoftwareInstance.%23RunningSoftware%3AHostedSoftware%3AHost%3AHost.name%20'
    #    'AS%20%27Server%20Name%27&offset=0&limit=0'
    # )
    if database_name:
        query = (
        f'query=search%20Database%20where%20type%20%3D%20%27Oracle%20Database%27%20and%20cdm_component_alias_suffix%20matches%20%27{database_name}%3A%27%20%20show%20%20cdm_component_alias_suffix%2C%20%23Detail%3ADetail%3AElementWithDetail%3ASoftwareInstance.%23RunningSoftware%3AHostedSoftware%3AHost%3AHost.name&offset=0&limit=0'
        )
    if server_name:
        query = (
        f'query=search%20Database%20where%20type%20%3D%20%27Oracle%20Database%27%20and%20%23Detail%3ADetail%3AElementWithDetail%3ASoftwareInstance.%23RunningSoftware%3AHostedSoftware%3AHost%3AHost.name%20matches%20%27%5E{server_name}%27%20show%20%20cdm_component_alias_suffix%2C%20%23Detail%3ADetail%3AElementWithDetail%3ASoftwareInstance.%23RunningSoftware%3AHostedSoftware%3AHost%3AHost.name%20as%20%27db_host_name%27&offset=0&limit=0'
        )
    token = ('NDpkYmE6OjptdmNTdUU0bTJVRU0zME9GT1JwSnJEd05lZ0xYNHZSaFFrVVVSZ0Q3MG'
        'hiSmpta0U2N2Qwc1E6MC1hMzNlOTcwYmIyOGYzYmJlNmM4MWFhOGNkZGU3ZWE5YzBh'
        'ZDVkNGU1NTZjZjU4NzY5NjM5OWUyZTIzMmJkNjNl')

    url = base_url + query
    headers = {
        'accept': 'application/json',
        'Authorization': f'Bearer {token}'
    }

    response = requests.get(url, headers=headers, verify=False)
    return response.json()[0]['results']


def get_servername_for_database(results, database_name):
    # remove duplicates
    servers = list(set([server for db, server in results if database_name in db]))
    return servers  #this is a list

def get_databases_for_servername(results, servername):
    databases = list(set([db.split(':')[0] for db, host in results if servername in host]))
    return databases

def get_servers_from_name(results, servername):
    pattern = re.compile(servername)
    matching_servers = [server_name for _, server_name in results if pattern.search(server_name)]
    return matching_servers

def main():
    parser = argparse.ArgumentParser(description='Query database or servername.')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-d', '--database', type=str, help='Get the server for the given database.')
    group.add_argument('-s', '--servername', type=str, help='Get databases on given server.')
    group.add_argument('-p', '--server_pattern', type=str, help='List all server matching')
    parser.add_argument('-g', '--group_name', type=str, help='Create a yaml output for the patterns servers with this group name')

    args = parser.parse_args()
    print(f"\n")
    if args.server_pattern and not args.group_name:
        args.group_name="fake_group"

    if args.database:
        results = fetch_data(database_name=args.database)
        servers = get_servername_for_database(results, args.database)
        if not servers:
            print(f"No servername found for database {args.database}")
        else:
            for server in servers:
                print(f"Server for {GREEN}{args.database}{RESET}: {server}")

    if args.servername:
        results = fetch_data(server_name=args.servername)
        databases = get_databases_for_servername(results, args.servername)
        if databases:
            print(f"Databases for {GREEN}{args.servername}{RESET}:")
            for db in databases:
              print(f"  - {db}")
        else:
            print(f"No databases found for servername '{args.servername}'.")

    if args.server_pattern:
        results = fetch_data(server_name=args.server_pattern)
        server_list=get_servers_from_name(results, args.server_pattern)
        print(f"{args.group_name}:")
        print("  hosts:")
        for server in list(set(server_list)):
            server = server.replace(".corp.ubp.ch", "")
            print(f"    {server}:")
    print(f"\n")

if __name__ == "__main__":
    main()

# Wundertools Native

Configuration for setting up Drupal development environment. Based on Wundertools built by Wunder.

### What is this for

Running multiple Drupal sites on the same time with as little overhead (virtualisation) as possible. 

### Requirements

- Centos7
- Python 2.7 

### Usage

Clone the repository in a folder of your choice

    git clone git@github.com:artursv/WunderToolsNative.git && cd WunderToolsNative

Copy the default configuration file.

    cp exaple.local.yml local.yml

Provision your laptop

    ./provision.sh

Provision a specific role.

    ./provision.sh -t nginx

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


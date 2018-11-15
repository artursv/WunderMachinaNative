# Wundertools Native

Wrapper scripts for Ansible playbooks that aid in creating fast and stable Drupal development environment. Based on [WunderTools](https://wundertools.wunder.io) built by [Wunder](https://wunder.io/).

### What is this for

Running multiple Drupal sites at the same time with as no overhead.

### Requirements

- Centos7
- Python 2.7 

### Usage

Clone the repository in a folder of your choice

    git clone git@github.com:artursv/WunderToolsNative.git && cd WunderToolsNative

Copy the default configuration file.

    cp exaple.local.yml local.yml

Provision everything.

    ./provision.sh

Provision a specific role.

    ./provision.sh -t nginx

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details


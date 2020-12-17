# ccli

Cryptopus Command Line Client

## Installation

`gem install ccli`

This will install the `cry` command including its dependencies

## Features

- Fetch account data from Cryptopus
- List accessable teams in Cryptopus
- Sync Openshift/Kubernetes Secrets to Cryptopus
- Sync Secrets from Cryptopus to Openshift/Kubernetes

## Usage

[Receiving the login token from Cryptopus](docs/get_login_token.md)

### Kubernetes/Openshift

#### Required tools

First you'll have to install either [oc](https://docs.openshift.com/container-platform/4.3/cli_reference/openshift_cli/getting-started-cli.html#installing-the-cli) or [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) depending on your usage

#### Labeling secret to be synced

So that a secret even gets considered by the `ccli`, you have to add the `cryptopus-sync=true` label to your secret:

**oc:** `oc label secret <secret-name> cryptopus-sync=true`


**kubectl:** `kubectl label secret <secret-name> cryptopus-sync=true`

### Commands

```
  Command:           Summary:

  account            Fetches an account by the given id          
  folder             Selects the Cryptopus folder by id          
  help               Display global or [command] help documentation              
  k8s-secret-pull    Pulls secret from Kubectl to Cryptopus              
  k8s-secret-push    Pushes secret from Cryptopus to Kubectl             
  login              Logs in to the ccli         
  logout             Logs out of the ccli                
  ose-secret-pull    Pulls secret from Openshift to Cryptopus            
  ose-secret-push    Pushes secret from Cryptopus to Openshift           
  teams              Lists all available teams           
  use                Select the current folder   
```

Show more specific documentation by calling `cry help <command>`


## Development

### Prerequisites

You will need the following things properly installed on your computer:

- [Git (Version Control System)](http://git-scm.com/)
- [RVM (Ruby Version Manager)](http://rvm.io/)

### Setup

- `rvm install 2.6.0`
- `gem install bundler`
- `bundle install`

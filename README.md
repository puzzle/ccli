# ccli

Command Line Client for [Cryptopus](https://github.com/puzzle/cryptopus)

## Installation

`gem install ccli`

This will install the `cry` command including its dependencies

## Features

- Fetch encryptable data from Cryptopus
- List accessable teams in Cryptopus

## Usage

[Receiving the login token from Cryptopus](docs/get_login_token.md)

### Commands

```
  Command:           Summary:

  encryptable        Fetches an encryptable by the given id
  folder             Selects the Cryptopus folder by id
  help               Display global or [command] help documentation
  login              Logs in to the ccli
  logout             Logs out of the ccli
  teams              Lists all available teams
  use                Select the current folder
```

Show more specific documentation by calling `cry help <command>`

### Account

#### Logging in

Use the ccli login copy button from the UI or do it manually:

    user=<my-user>
    token=<my-token>
    url=https://cryptopus.example.com

    cry login $(echo -n "$user:$token" | base64)@$url

#### Retrieving

To retreive encryptable data as yaml:

```
cry encryptable 42 > encryptable.yaml
```
Retreiving encryptable's password and assign it to a variable:

```
PASSWORD=$(cry encryptable 42 --password)
```

#### Updating

not supported yet by ccli

## Development

### Prerequisites

You will need the following things properly installed on your computer:

- [Git (Version Control System)](http://git-scm.com/)
- [RVM (Ruby Version Manager)](http://rvm.io/)

### Setup

- `rvm install 2.6.0`
- `gem install bundler`
- `bundle install`

### Running tests

`bundle exec rspec`

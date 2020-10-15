# ccli

Cryptopus Command Line Client

## Installation

`sudo gem install ccli`

This will install the `cry` command including its dependencies

## Usage

### Labeling secret to be synced

So that a secret even gets considered by the `ccli`, you have to add the `cryptopus-sync=true` label to your secret:

**oc:** `oc label secret <secret-name> cryptopus-sync=true`


**kubectl:** `kubectl label secret <secret-name> cryptopus-sync=true`

### Commands

#### Help

**Synopsis:** `cry help <command>`

**Summary:** Display global or `<command>` help documentation

#### Login

**Synopsis:** `cry login <base64_encoded_token>@<host>`

**Summary:** Logs in to the ccli

The token has to be base64 encoded of a string constructed like this: `<username>:<auth_token>`
These are the credentials of the desired api-user inside Cryptopus.

#### Logout

**Synopsis:** `cry logout`

**Summary:** Logs out of the ccli

#### Account

**Synopsis:** `cry account <id>`

**Summary:** Fetches an account by the given id

**Options:** 

- --username: Only show the username of the account

- --password: Only show the password of the account

#### Teams

**Synopsis:** `cry teams`

**Summary:** Lists the accessible teams and their folders.

#### Use

**Synopsis:** `cry use <team>/<folder>`

**Summary:** Selects the current team and folder by the given name

#### Folder

**Synopsis:** `cry folder <id>`

**Summary:** Selects the Cryptopus folder by id

#### Ose-Secret-Pull

**Synopsis:** `cry ose-secret-pull <secret-name>`

**Summary:** Pulls the secret from Openshift to Cryptopus. If no secret is given, it will pull all secrets.

#### Ose-Secret-Push

**Synopsis:** `cry ose-secret-push <secret-name>`

**Summary:** Pushes the secret from Cryptopus to Openshift

## Development

### Prerequisites

You will need the following things properly installed on your computer:

- [Git (Version Control System)](http://git-scm.com/)
- [RVM (Ruby Version Manager)](http://rvm.io/)

### Setup

- `rvm install 2.6.0`
- `gem install bundler`
- `bundle install`

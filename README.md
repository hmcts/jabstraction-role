# jabstraction

Required abstraction layer that sits atop Jenkins, allowing limited access
to specified jobs.

ROPS-788

## Usage

Add config to `templates/config.yml` like so:

```yaml
exampleusername01:
  bootstrap:
    AZURE_PROFILE: mgmt
    AZURE_TAGS: "env:demo,role:deployapp"
    ANSIBLE_TAGS: all
    test_mode: false
    HOSTNAME_PARAM: ""
    SSH_USER: jenkinspush
    SSH_KEY_FILE: /var/home/jenkinspush/.ssh/id_rsa
    SSH_PORT: 2332
```
Above example would allow `exampleusername01` to run `bootstrap` job  with sufficient parameters to bootstrap the jabstraction server.

Providing the incorrect/wrong/not enough parameters will result in internal server error, as will most errors.

Run ansible management (Steal tags from above example) to deploy config and reload jabstraction.

Access at https://jabstraction.example.com

Log in with your ldap user.

## Testing

Needs something like this in `env.rb` if you're going to test locally (though you'll also need to be able to access ldap...)

```
ENV['jenkins_user'] = "avalidjenkinsuserthatcanbuildonprod"
ENV['jenkins_password'] = "thisismypassword"
ENV['cookie_secret'] = "someselectionofcharacters"
```

Can add `session[:logged_in] = true` to the `get /` block if you want to skip auth in testing


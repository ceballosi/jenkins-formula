# Salt Formula for Setting Up Jenkins

## Available States

```
jenkins
jenkins.agent
jenkins.cli
jenkins.config
jenkins.jobs
jenkins.nginx
jenkins.plugins
```

### State: jenkins

The sls file of init.sls runs for this state.

1. Create the group and user of jenkins.
2. Update the package manager's correct repository depending on the OS family.
3. Install Jenkins from the updated package repository.

### State: jenkins.agent

The sls file of agent.sls runs for this state.

1. Create the appropriate settings for Jenkins agent without installing a Jenkins master. This can be separately used by any independent Jenkins agent setup.

### State: jenkins.cli

The sls file of cli.sls runs for this state. It is rarely used on its own but as a help for plugins.sls.

Due to differences in the scope of functionality of netcat between RedHat and Debian/other Linux distributions, nc -z does not work on RedHat since the option -z simply does not exist. Hence by default, RedHat distro will use curl instead. If you are on Debian distro, please feel free to use a custom versin of netcat. You can define that in your pillar file as netcat_pkg: your_nc_package.

1. Listen to Jenkins server
2. Find out if it is serving data
3. Download the Jenkins CLI jar file
4. Login with the preconfigured admin user and password
5. Find out if Jenkins is responding with the Jenkins CLI

### State: jenkins.config

The sls file of config.sls runs for this state.

1. Get all Jenkins master configurations and settings from a remote git repository.
2. Change the ownership of JENKINS_HOME since the git repo is forcibly copied over the old configuration files by the root user.
3. Restart the Jenkins service.

### State: jenkins.jobs

The sls file of jobs.sls runs for this state.

1. Programmatically add states for jobs that you define in the pillar file.

### State: jenkins.nginx

The sls file of nginx.sls runs for this state.

1. Add a jenkins nginx entry.
2. It depends on the nginx formula being installed and
requires manual inclusion `nginx` and `jenkins` states in your `top.sls` to
function, in this order: `jenkins`, `nginx`, `jenkins.nginx`.

### State: jenkins.plugins

The sls file of plugins.sls runs for this state.

1. Updates the plugins list of versioning from the Jenkins server.
2. Programmatically generates states depending on the entries in pillar for plugins to be installed or disabled.
3. Restart Jenkins service after the last plugin installation.

## Pillar Customisations

Put your pillar settings to the directory /srv/salt/pillar on your salt-master machine. Inspect the pillar.example file to see the structure of the pillar. Inspect map.jinja to see what variables are there to customise with pillar.

```
jenkins:
  lookup:
    port: 80
    home: /usr/local/jenkins
    user: jenkins
    group: www-data
    server_name: ci.example.com
```

Contributing to This Project

1. Fork this repository.
2. If you need to include this repo in a git superproject, then make your fork a git submodule.
3. Submit Pull Request when you have developed a new feature or made a fix.
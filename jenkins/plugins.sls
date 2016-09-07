include:
  - jenkins
  - jenkins.cli

{% from "jenkins/map.jinja" import jenkins with context %}
{% import "jenkins/macros/cli_macro.jinja" as cli_macro %}

{%- macro fmtarg(prefix, value)-%}
{{ (prefix + ' ' + value) if value else '' }}
{%- endmacro -%}
{%- macro jenkins_cli(cmd) -%}
{{ ' '.join(['java', '-jar', jenkins.cli_path, '-s', jenkins.master_url, fmtarg('-i', jenkins.get('privkey')), cmd]) }} {{ ' '.join(varargs) }}
{%- endmacro -%}

{% set plugin_cache = "{0}/updates/default.json".format(jenkins.home) %}

get_new_jenkins_plugins_registry:
  file.directory:
    - name: {{ "{0}/updates".format(jenkins.home) }}
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - mode: 755
    - require:
      - sls: jenkins
      - sls: jenkins.cli
  cmd.run:
    - unless: test -f {{ plugin_cache }}
    - name: "curl -L {{ jenkins.plugins.updates_source }} | sed '1d;$d' > {{ plugin_cache }}"
    - require:
      - file: get_new_jenkins_plugins_registry

{% set plugins = jenkins.plugins.default + jenkins.plugins.installed if jenkins.install_default_plugins else jenkins.plugins.installed %}
{% for plugin in plugins %}
{% if plugin == 'ldap' and jenkins.ldap_host is defined and jenkins.ldap_root_dn is defined and jenkins.ldap_user is defined and jenkins.ldap_secret is defined %}
enable_ldap_security:
  file.blockreplace:
    - name: {{ jenkins.home }}/config.xml
    - marker_start: '</authorizationStrategy>'
    - marker_end: '<disableRememberMe>false</disableRememberMe>'
    - content: >
                <securityRealm class="hudson.security.LDAPSecurityRealm" plugin="ldap@1.12">
                  <server>ldap://{{ jenkins.ldap_host }}</server>
                  <rootDN>{{ jenkins.ldap_root_dn }}</rootDN>
                  <inhibitInferRootDN>false</inhibitInferRootDN>
                  <userSearchBase></userSearchBase>
                  <userSearch>uid={0}</userSearch>
                  <groupMembershipStrategy class="jenkins.security.plugins.ldap.FromGroupSearchLDAPGroupMembershipStrategy">
                    {% if jenkins.ldap_groups is defined and jenkins.ldap_groups is iterable %}
                    <filter>(|{% for group in jenkins.ldap_groups %}({{ group }}){% endfor %})</filter>
                    {% endif %}
                  </groupMembershipStrategy>
                  <managerDN>{{ jenkins.ldap_user }}</managerDN>
                  <managerPasswordSecret>{{ jenkins.ldap_secret }}</managerPasswordSecret>
                  <disableMailAddressResolver>false</disableMailAddressResolver>
                  <displayNameAttributeName>displayname</displayNameAttributeName>
                  <mailAddressAttributeName>mail</mailAddressAttributeName>
                  <userIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
                  <groupIdStrategy class="jenkins.model.IdStrategy$CaseInsensitive"/>
                </securityRealm>
    - show_changes: True
    - backup: .bak
    - require:
      - cmd: get_new_jenkins_plugins_registry
{% endif %}

jenkins_install_plugin_{{ plugin }}:
  cmd.run:
    - name: {{ jenkins_cli('install-plugin', plugin) }}
    - require:
      - cmd: get_new_jenkins_plugins_registry
    - watch_in:
      - service: restart_jenkins_after_plugins_installation
    - unless: {{ jenkins_cli('list-plugins') }} | grep {{ plugin }}
{% endfor %}

{% for plugin in jenkins.plugins.disabled %}
jenkins_disable_plugin_{{ plugin }}:
  file.managed:
    - name: {{ jenkins.home }}/plugins/{{ plugin }}.jpi.disabled
    - user: {{ jenkins.user }}
    - group: {{ jenkins.group }}
    - contents: ''
    - require:
      - cmd: get_new_jenkins_plugins_registry
    - watch_in:
      - service: restart_jenkins_after_plugins_installation
{% endfor %}

restart_jenkins_after_plugins_installation:
  service.running:
    - name: jenkins

remove_initial_password:
  file.absent:
    - name: {{ jenkins.home }}/secrets/initialAdminPassword
    - require:
      - service: restart_jenkins_after_plugins_installation

finish_jenkins_config:
  cmd.run:
    - name: cp {{ jenkins.home }}/jenkins.install.UpgradeWizard.state {{ jenkins.home }}/jenkins.install.InstallUtil.lastExecVersion
    - unless: test -f {{ jenkins.home }}/jenkins.install.InstallUtil.lastExecVersion
    - require:
      - service: restart_jenkins_after_plugins_installation

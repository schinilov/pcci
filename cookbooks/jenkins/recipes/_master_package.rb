#
# Cookbook Name:: jenkins
# Recipe:: _master_package
#
# Author: Guilhem Lettron <guilhem.lettron@youscribe.com>
# Author: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013, Youscribe
# Copyright 2014, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

case node['platform_family']
when 'debian'
  include_recipe 'apt::default'

  apt_repository 'jenkins' do
    uri          'http://pkg.jenkins-ci.org/debian'
    distribution 'binary/'
    key          'https://jenkins-ci.org/debian/jenkins-ci.org.key'
  end

  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  template '/etc/default/jenkins' do
    source   'jenkins-config-debian.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end
when 'rhel'
  include_recipe 'yum::default'

  yum_repository 'jenkins-ci' do
    baseurl 'http://pkg.jenkins-ci.org/redhat'
    gpgkey  'https://jenkins-ci.org/redhat/jenkins-ci.org.key'
  end

  package 'jenkins' do
    version node['jenkins']['master']['version']
  end

  template '/etc/sysconfig/jenkins' do
    source   'jenkins-config-rhel.erb'
    mode     '0644'
    notifies :restart, 'service[jenkins]', :immediately
  end

  directory "#{node['jenkins']['master']['build_job_directory']}" do
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    recursive true
  end

  template "#{node['jenkins']['master']['build_job_directory']}/config.xml" do
    source   'config.xml.erb'
    mode     '0644'
    action :create
    #notifies :restart, 'service[jenkins]', :immediately
  end

  template "#{node['jenkins']['master']['home']}/hudson.tasks.Maven.xml" do
    source   'hudson.tasks.Maven.xml.erb'
    mode     '0644'
      variables(
      :path_to_maven => '/usr/local/maven-3.1.1'
      )
    action :create
    notifies :restart, 'service[jenkins]', :immediately
  end
end

service 'jenkins' do
  supports status: true, restart: true, reload: true
  action  [:enable, :start]
# notifies :create, 'ruby_block[block_until_jenkins_up]', :immediate
 notifies :run, 'script[install_git_plugin]'
end

#execute "Start_jenkins_service" do
#   command "service jenkins start"
#end

#ruby_block "block_until_jenkins_up" do
#  block do
#    until IO.popen("netstat -lnt").entries.select { |entry|
#        entry.split[3] =~ /:#{node['jenkins']['master']['port']}$/
#      }.size == 1   
#      Chef::Log.debug "service[jenkins] not listening on port #{node['jenkins']['master']['port']}"
#      sleep 1
#    end
#  end
#  action :nothing
#end

script 'install_git_plugin' do
  interpreter "bash"
  user "root"
  cwd "/home/vagrant"
  code <<-EOH
  while [ `netstat -lnt | grep #{node['jenkins']['master']['port']} > /dev/null; echo $?` -ne 0 ]; do echo "Wait for Jenkins"; sleep 1; done
  wget -O default.js http://updates.jenkins-ci.org/update-center.json
  sed '1d;$d' default.js > default.json
  sleep 20
  curl -X POST -H "Accept: application/json" -d @default.json #{node['jenkins']['master']['endpoint']}/updateCenter/byId/default/postBack
  sleep 5
  wget #{node['jenkins']['master']['endpoint']}/jnlpJars/jenkins-cli.jar
  sleep 5
  java -jar jenkins-cli.jar -s #{node['jenkins']['master']['endpoint']} install-plugin envinject -deploy
  java -jar jenkins-cli.jar -s #{node['jenkins']['master']['endpoint']} install-plugin git -deploy -restart
  java -jar jenkins-cli.jar -s #{node['jenkins']['master']['endpoint']} reload-configuration
  EOH
  action :nothing
end


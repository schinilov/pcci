#
# Cookbook Name:: jenkins
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
#include_recipe "master"
#Comment for new feature
#Comment #2 for new feature
#Comment for cherry-pick
begin
#  include_recipe "jenkins::java"
  include_recipe "jenkins::master"
end

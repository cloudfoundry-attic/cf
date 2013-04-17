#!/usr/bin/env ruby
# Copyright (c) 2009-2011 VMware, Inc.
$:.unshift(File.dirname(__FILE__) + '/lib')

require 'rubygems'
require 'bundler/setup'

require 'caldecott'
require 'sinatra'
require 'json'
require 'eventmachine'

port = ENV['PORT']
port ||= 8081

# add vcap specific stuff to Caldecott
class VcapHttpTunnel < Caldecott::Server::HttpTunnel
  get '/info' do
    { "version" => '0.0.4' }.to_json
  end

  def self.get_tunnels
    super
  end

  get '/services' do
    services_env = ENV['VCAP_SERVICES']
    return "no services env" if services_env.nil? or services_env.empty?
    services_env
  end

  get '/services/:service' do |service_name|
    services_env = ENV['VCAP_SERVICES']
    not_found if services_env.nil?

    services = JSON.parse(services_env).values.flatten(1)
    service = services.find { |s| s["name"] == service_name }
    not_found if service.nil?
    service["credentials"].to_json
  end
end

VcapHttpTunnel.run!(:port => port, :auth_token => ENV["CALDECOTT_AUTH"])

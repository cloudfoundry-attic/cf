require 'sinatra'

class FakeCloudController < Sinatra::Base
  SERVICE = {
      'metadata' => {
          'guid' => '7376eb18-f465-4103-8ee5-c17444911d1f',
          'url' => '/v2/services/7376eb18-f465-4103-8ee5-c17444911d1f',
          'created_at' => Time.now,
          'updated_at' => Time.now
      },
      'entity' => {
          'label' => 'GonzoDB',
          'name' => 'GonzoBeans'
      }
  }

  PLAN = {
      'metadata' => {
          'guid' => '54991e4b-a829-48ba-bfdf-bdb8b1615a86',
          'url' => '/v2/service_plans/54991e4b-a829-48ba-bfdf-bdb8b1615a86',
          'created_at' => Time.now,
          'updated_at' => Time.now
      },
      'entity' => {
          'name' => 'bronze',
      }
  }

  SERVICE_INSTANCE = {
      'metadata' => {
          'guid' => 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'url' => '/v2/service_instances/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
          'created_at' => Time.now,
          'updated_at' => Time.now
      },
      'entity' => {
          'name' => 'some-provided-instance',
          'type' => 'user_provided_service_instance'
      }
  }

  SERVICE_BINDING = {
      'metadata' => {
          'guid' => 'aaaaaaaa-aaaa-aaaa-aaaa-bbbbbbbbbbbb',
          'url' => '/v2/service_instances/aaaaaaaa-aaaa-aaaa-aaaa-bbbbbbbbbbbb',
          'created_at' => Time.now,
          'updated_at' => Time.now
      },
      'entity' => {
          'service_instance' => SERVICE_INSTANCE
      }
  }

  @service_bindings = []

  @requests = []

  class << self
    attr_accessor :requests, :service_bindings

    def last_request
      requests.last
    end

    def reset
      requests.clear
      service_bindings.clear
    end
  end

  get '/v2/service_brokers' do
    self.class.requests << request

    broker_guid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
    body = {
        'total_results' => 1,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => [{
                            'metadata' => {
                                'guid' => broker_guid,
                                'url' => 'http://cc.example.com/v2/service_brokers/#{broker_guid}',
                                'created_at' => Time.now,
                                'updated_at' => Time.now,
                            },
                            'entity' => {
                                'name' => 'my-custom-service',
                                'broker_url' => 'http://broker.example.com/',
                            }
                        }]
    }.to_json
    [200, {}, body]
  end

  post '/v2/service_brokers' do
    self.class.requests << request

    body = {
        metadata: {
            guid: SecureRandom.uuid
        }
    }.to_json

    [200, {}, body]
  end

  delete '/v2/service_brokers/:guid' do
    self.class.requests << request
    204
  end

  put '/v2/service_brokers/:guid' do
    self.class.requests << request
    201
  end

  get '/v2/spaces/:guid/service_instances' do
    body = {
        'total_results' => 1,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => [SERVICE_INSTANCE]
    }.to_json

    [200, {}, body]
  end

  get '/v2/service_instances/:guid/service_bindings' do
    body = {
        'total_results' => self.class.service_bindings.count,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => self.class.service_bindings
    }.to_json

    [200, {}, body]
  end

  get '/v2/apps/:guid/service_bindings' do
    body = {
        'total_results' => self.class.service_bindings.count,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => self.class.service_bindings
    }.to_json

    [200, {}, body]
  end

  post '/v2/service_bindings' do
    self.class.service_bindings << SERVICE_BINDING

    body = SERVICE_BINDING.to_json

    [201, {}, body]
  end

  delete '/v2/service_bindings/:guid' do
    204
  end

  get '/v2/services' do
    body = {
        'total_results' => 1,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => [SERVICE]
    }.to_json

    [200, {}, body]
  end

  get '/v2/services/:guid/service_plans' do
    body = {
        'total_results' => 1,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => [PLAN]
    }.to_json

    [200, {}, body]
  end

  post '/v2/service_instances' do
    body = SERVICE_INSTANCE.to_json

    [201, {}, body]
  end

  post '/v2/user_provided_service_instances' do
    body = SERVICE_INSTANCE.to_json

    [201, {}, body]
  end

  get '/v2/spaces/:guid' do
    body = {
        'metadata' => {
            'guid' => '51d80581-6d60-4de0-855e-66ffa96fbbb2',
            'url' => '/v2/spaces/51d80581-6d60-4de0-855e-66ffa96fbbb2',
            'created_at' => Time.now,
            'updated_at' => nil
        },
        'entity' => {
            'name' => 'jz-play'
        }
    }.to_json

    [200, {}, body]
  end

  get '/v2/spaces/:guid/apps' do
    body = {
        'total_results' => 1,
        'total_pages' => 1,
        'prev_url' => nil,
        'next_url' => nil,
        'resources' => [
            'metadata' => {
                'guid' => '81d80581-6d60-4de0-855e-66ffa96fbbb2',
                'url' => '/v2/spaces/81d80581-6d60-4de0-855e-66ffa96fbbb2/apps',
                'created_at' => Time.now,
                'updated_at' => nil
            },
            'entity' => {
                'name' => 'services_env_test_app'
            }
        ]
    }.to_json

    [200, {}, body]
  end

  get '/responsive' do
    200
  end
end

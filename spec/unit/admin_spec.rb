require 'spec_helper'

HOST = 'localhost'
PORT = 8070

CONFIG_FILE = '/tmp/admin_ui.yml'
DATA_FILE   = '/tmp/admin_ui_data.json'
LOG_FILE    = '/tmp/admin_ui.log'
STATS_FILE  = '/tmp/admin_ui_stats.json'

ADMIN_USER     = 'admin'
ADMIN_PASSWORD = 'admin_passw0rd'

USER          = 'user'
USER_PASSWORD = 'user_passw0rd'


describe Admin do
  before(:all) do
    config = 
    {
      :cc                   => 'postgres://ccadmin:c1oudc0w@localhost:5524/ccdb',
      :cloud_controller_uri => 'http://api.localhost',
      :data_file            => DATA_FILE,
      :log_file             => LOG_FILE,
      :log_files            => [],
      :mbus                 => 'nats://nats:c1oudc0w@localhost:4222',
      :monitored_components => ['ALL'],
      :port                 => PORT,
      :receiver_emails      => [],
      :sender_email         => {:server => 'localhost', :account => 'system@localhost'},
      :stats_file           => STATS_FILE,
      :uaa                  => 'postgres://uaaadmin:c1oudc0w@localhost:5524/uaadb',
      :ui_admin_credentials => {:username => ADMIN_USER, :password => ADMIN_PASSWORD},
      :ui_credentials       => {:username => USER, :password => USER_PASSWORD}
    }

    File.open(CONFIG_FILE, 'w') { |file| file.write(JSON.pretty_generate(config)) }

    project_path = File.join(File.dirname(__FILE__), '../..')
    spawn_opts = {:chdir => project_path, :out => '/dev/null', :err => '/dev/null'}

    @pid = Process.spawn({}, "ruby bin/admin -c #{CONFIG_FILE}", spawn_opts)

    sleep(5)
  end
  
  after(:all) do
    Process.kill('TERM', @pid)
    Process.wait(@pid)

    cleanup_files_pid = Process.spawn({}, "rm -fr #{CONFIG_FILE} #{DATA_FILE} #{LOG_FILE} #{STATS_FILE}")
    Process.wait(cleanup_files_pid)
  end

  context 'Login required, performed and failed' do
    
    it 'login fails as expected' do
      @http   = Net::HTTP.new(HOST, PORT)
      request = Net::HTTP::Post.new("/login?username=#{ADMIN_USER}&password=#{USER_PASSWORD}")
      request['Content-Length'] = 0

      response = @http.request(request)
      fail_with('Unexpected http status code') unless response.is_a?(Net::HTTPSeeOther)

      location = response['location']
      location.should eq("http://#{HOST}:#{PORT}/login.html?error=true")
    end
  end

  context 'Login required, performed and succeeded' do

    before(:all) do
      @http   = Net::HTTP.new(HOST, PORT)
      request = Net::HTTP::Post.new("/login?username=#{ADMIN_USER}&password=#{ADMIN_PASSWORD}")
      request['Content-Length'] = 0

      response = @http.request(request)
      fail_with('Unexpected http status code') unless response.is_a?(Net::HTTPSeeOther)

      location = response['location']
      location.should eq("http://#{HOST}:#{PORT}/application.html?user=#{ADMIN_USER}")

      @cookie = response['Set-Cookie']
      @cookie.should_not be_nil
    end

    after(:all) do
      @http   = nil
      @cookie = nil
    end

    def get_json(path)
      request = Net::HTTP::Get.new(path)
      request['Cookie'] = @cookie

      response = @http.request(request)
      fail_with('Unexpected http status code') unless response.is_a?(Net::HTTPOK)

      body = response.body
      body.should_not be_nil

      JSON.parse(body)
    end

    def verify_empty_items(path)
      json = get_json(path)

      items = json['items']
      items.should_not be_nil
      items.length.should eq(0)
    end

    it '/applications succeeds' do
      verify_empty_items('/applications')
    end

    it '/cloudControllers succeeds' do
      verify_empty_items('/cloudControllers')
    end

    it '/components succeeds' do
      verify_empty_items('/components')
    end

    it '/dropletExecutionAgents succeeds' do
      verify_empty_items('/dropletExecutionAgents')
    end

    it '/gateways succeeds' do
      verify_empty_items('/gateways')
    end

    it '/healthManagers succeeds' do
      verify_empty_items('/healthManagers')
    end

    it '/logs succeeds' do
      verify_empty_items('/logs')
    end

    it '/organizations succeeds' do
      verify_empty_items('/organizations')
    end

    it '/routers succeeds' do
      verify_empty_items('/routers')
    end

    it '/settings succeeds' do
      json = get_json('/settings')

      json['cloudControllerURI'].should_not be_nil
      json['tasksRefreshInterval'].should_not be_nil
      json['admin'].should_not be_nil
    end

    it '/spaces succeeds' do
      verify_empty_items('/spaces')
    end

    it '/tasks succeeds' do
      verify_empty_items('/tasks')
    end

    it '/users succeeds' do
      verify_empty_items('/users')
    end
  end

  context 'Login required, but not performed' do

    before(:all) do
      @http = Net::HTTP.new(HOST, PORT)
    end

    after(:all) do
      @http = nil
    end

    def redirects_as_expected(path)
      request = Net::HTTP::Get.new(path)

      response = @http.request(request)
      fail_with('Unexpected http status code') unless response.is_a?(Net::HTTPSeeOther)

      location = response['location']
      location.should eq("http://#{HOST}:#{PORT}/login.html")
    end

    it '/applications redirects as expected' do
      redirects_as_expected('/applications')
    end

    it '/cloudControllers redirects as expected' do
      redirects_as_expected('/cloudControllers')
    end

    it '/components redirects as expected' do
      redirects_as_expected('/components')
    end

    it '/dropletExecutionAgents redirects as expected' do
      redirects_as_expected('/dropletExecutionAgents')
    end

    it '/gateways redirects as expected' do
      redirects_as_expected('/gateways')
    end

    it '/healthManagers redirects as expected' do
      redirects_as_expected('/healthManagers')
    end

    it '/logs redirects as expected' do
      redirects_as_expected('/logs')
    end

    it '/organizations redirects as expected' do
      redirects_as_expected('/organizations')
    end

    it '/routers redirects as expected' do
      redirects_as_expected('/routers')
    end

    it '/settings redirects as expected' do
      redirects_as_expected('/settings')
    end

    it '/spaces redirects as expected' do
      redirects_as_expected('/spaces')
    end

    it '/tasks redirects as expected' do
      redirects_as_expected('/tasks')
    end

    it '/users redirects as expected' do
      redirects_as_expected('/users')
    end

  end

  context 'Login not required' do

    before(:all) do
      @http = Net::HTTP.new(HOST, PORT)
    end

    after(:all) do
      @http = nil
    end

   def get_response(path)
      request = Net::HTTP::Get.new(path)

      response = @http.request(request)
      fail_with('Unexpected http status code') unless response.is_a?(Net::HTTPOK)

      response
    end

    def get_body(path)
      response = get_response(path)

      body = response.body
      body.should_not be_nil

      body
    end

    def get_json(path)
      body = get_body(path)

      JSON.parse(body)
    end

    it '/ succeeds' do
      get_body('/')
    end

    it '/favicon.ico succeeds' do
      get_response('/favicon.ico')
    end

    it '/statistics succeeds' do
      json = get_json('/statistics')

      json['label'].should_not be_nil

      items = json['items']
      items.should_not be_nil
      items.length.should eq(0)
    end

    it '/stats succeeds' do
      get_body('/stats')
    end

  end

end
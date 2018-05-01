require 'sinatra'
require 'jenkins_api_client'
require 'yaml'
require 'net-ldap'


# ENV for secrets and whatnot
load './env.rb' if File.exists?('./env.rb')

# Sinatra gubbins
set :environment, :production
set :port, 4568
use Rack::Session::Cookie, :key => 'rack.session', :path => '/', :secret => "#{ENV['cookie_secret']}"

helpers do
  def authorise!
    redirect '/login' unless session[:logged_in] == true
  end
end

config = YAML.load(File.open("config.yml"))

get '/' do
  redirect '/list'
end

get '/login' do
  erb :login
end

post '/login' do
  if config.keys.include?(params[:username])
    ldap = Net::LDAP.new(:host => "ldap01.example.com",
       :port => 636,
       :encryption => :simple_tls,
       :auth => {
             :method => :simple,
             :username => "uid=#{params[:username]},ou=People,dc=example,dc=com",
             :password => params[:password]
       })

    if ldap.bind
     session[:logged_in] = true
     session[:username] = params[:username]
     redirect '/list'
    end
  else
    redirect '/login'
  end
end

get '/sign_out' do
  session.clear
  redirect '/login'
end


get '/list' do
  authorise!
  @title = "Jonkins"
  @client = JenkinsApi::Client.new(:server_url => 'https://build.example.com', :ssl => 'true',
        :username => "#{ENV['jenkins_user']}", :password => "#{ENV['jenkins_password']}")
  all_jobs = @client.job.list_all
  allowed_jobs = config[session[:username]].keys
  @jobs = all_jobs & allowed_jobs
  erb :list
end

get '/build/:job_name' do
  authorise!
  allowed_jobs = config[session[:username]].keys
  unless allowed_jobs.include? params[:job_name]
    session.clear
    redirect '/login'
  end
  @client = JenkinsApi::Client.new(:server_url => 'https://build.example.com', :ssl => 'true',
        :username => "#{ENV['jenkins_user']}", :password => "#{ENV['jenkins_password']}")
  user = session[:username]
  job_name = params[:job_name]
  job_params = config[user][job_name]
  if job_params == []
    @client.job.build(job_name)
  else
    @client.job.build(job_name, job_params)
  end
  incremented_version_number = @client.job.get_current_build_number(job_name)+1
  # Nasty sleep to give build time to start, avoiding 404
  sleep 8
  buildUrl = "https://build.example.com/job/" + job_name + "/" + incremented_version_number.to_s + "/console"
  redirect buildUrl
end

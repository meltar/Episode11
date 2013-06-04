require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra'
require "active_support/all"
require "cgi"

Rabl.register!

class LogRequest
  attr_reader :text, :time, :created_at, :execution_time, :user

  def initialize(time, text, exec_time, user)
    @text = text
    @time = time 
    @created_at = Time.now
    @execution_time = exec_time
    @user = user
  end

  @@log = []
  def self.log_request(time, text, exec_time, user=nil)
    if (user.nil?)
      @@log << LogRequest.new(time, text, exec_time, User.None)
    else 
      @@log << LogRequest.new(time, text, exec_time, user)
    end
  end

  def self.log
    @@log
  end

  def self.log_per_user(id)
    @@log.select { |i| i.user == id }
  end

  def self.clear_log!
    @@log = []
  end

end

class User
  def self.None
    @id = -1
  end
end

LogRequest.log_request(Time.now, "Just do it already", 5.minutes, "1011")

get '/' do
  if params != {}
    puts "params: #{params}"
    @logs = LogRequest.log_per_user(params.fetch("user"))
  else
    @logs = LogRequest.log
  end
  render :rabl, :logs, :format => "json"
end

post '/' do
  LogRequest.log_request params.fetch("time"), params.fetch("msg"), params.fetch("exec_time"), params.fetch("user")
  @logs = LogRequest.log
  render :rabl, :logs, :format => "json"
end

require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra'
require "active_support/all"

Rabl.register!

class LogRequest
  attr_reader :text, :time, :created_at, :execution_time
  def initialize(time, text, exec_time)
    @text = text
    @time = time 
    @created_at = Time.now
    @execution_time = exec_time
  end

  @@log = []
  def self.log_request(time, text, exec_time)
    @@log << LogRequest.new(time, text, exec_time)
  end

  def self.log
    @@log
  end

  def self.clear_log!
    @@log = []
  end

end

LogRequest.log_request Time.now, "Just do it already", 5.minutes

get '/' do
  @logs = LogRequest.log
  render :rabl, :logs, :format => "json"
end

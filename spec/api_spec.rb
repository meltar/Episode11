require_relative "../api"
require "rspec"
require "rack/test"

set :environment, :test

describe "The Api" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  before do
    LogRequest.clear_log!
    LogRequest.log_request(6.seconds.ago.utc, "Hello World", 11.hours)
    LogRequest.log_request(10.minutes.ago.utc, "User specific", 15.minutes, "951")
  end
  
  it "should return json array of log request" do
    get "/"
    json = JSON.parse(last_response.body)
    log_request = json.first["logrequest"]
    log_request.fetch("text").should eq("Hello World")
    time_in_utc = Time.parse(log_request.fetch("time"))
    time_in_utc.should be_within(1).of(6.seconds.ago.utc)
    exec_time = log_request.fetch("execution_time")
    exec_time.should be_within(1).of(11.hours)
  end

  it "should only return logs for a provided user id" do
    get("/?user=951")
    json = JSON.parse(last_response.body)
    json.count.should eq(1)
  end

  it "should be able to post a log" do
    get "/"
    json = JSON.parse(last_response.body)
    count = json.count
    post("/", { time: Time.now, msg: 'Posted request', exec_time: 3.minutes, user: "150" })
    json = JSON.parse(last_response.body)
    total = json.count
    total.should equal(count + 1)
  end
  
  it "should return a 401 error when a put request does not contain a user id" do
    post("/", { time: Time.now, msg: 'put request with user', exec_time: 35.seconds, user: "12" })
    last_response.should be_ok
    post("/", { time: 48.seconds.ago, msg: 'put request without user', exec_time: 2.minutes })
    last_response.status.should eq(401)
  end

  it "should not be ok with /wack" do
    get "/wack"
    last_response.should_not be_ok
  end
end


describe LogRequest do

  let(:subject) { LogRequest.new(45.minutes.ago, "Just Record it", 5.seconds, "811")}

  it "should have the text" do
    subject.text.should eq("Just Record it")
  end
  it "should keep the time" do
    subject.time.should be_within(0.01).of(45.minutes.ago)
  end
  it "should know how long it took to execute" do
    subject.execution_time.should be_within(0.01).of(5.seconds)
  end

  describe ":log" do
    before do
      LogRequest.clear_log!
      LogRequest.log_request(Time.now, "Now", 3.minutes, "500")
      LogRequest.log_request(Time.now, "Now", 3.minutes, "500")
    end
    it "should be an array-like thing" do
      LogRequest.log.count.should eq(2)
    end
    it "should request LogRequest" do
      LogRequest.log.first.should be_a(LogRequest)
    end

    it "can clear out the log" do
      LogRequest.clear_log!
      LogRequest.log.should be_empty
    end

  end
end


require 'webrick'
include WEBrick

dir = ARGV[0]
port = ARGV[1]
usr = ARGV[2]
pwd = ARGV[3]

authenticate = Proc.new do |req, res|
  HTTPAuth.basic_auth(req, res, '') do |user, password|
    user == usr && password == pwd
  end
end

s = HTTPServer.new(:Port => port, :ServerType => Daemon)
s.mount('/', HTTPServlet::FileHandler, dir,
  :FancyIndexing => true,
  :HandlerCallback => authenticate
)

trap('INT') { s.shutdown }
s.start
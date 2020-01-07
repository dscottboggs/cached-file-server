require "http"
require "option_parser"
require "./cached_static_server"

config = CachedStaticServer::CLI.build_server

server = HTTP::Server.new do |context|
  begin
    code, resp = config.serve context.request
    context.response.status_code = code
    resp.to_s context.response
  rescue e
    context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
    context.response.puts e.message
  end
end

addr = server.bind_tcp config.bind_address, config.port.to_i
puts "Serving files under #{config.parent_dir} at #{addr}"

server.listen

# Hack to prevent a segfault for static linking
{% if flag?(:static) %}
  require "llvm/lib_llvm"
  require "llvm/enums"
{% end %}

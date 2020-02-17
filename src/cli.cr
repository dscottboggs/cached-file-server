class CachedStaticServer::CLI
  def self.default_port : UInt16
    (ENV["port"]? || 12345).to_u16
  end

  def self.build_server(args = ARGV)
    port, parent, addr = default_port, Dir.current, "0.0.0.0"
    template = nil
    OptionParser.parse args do |parser|
      parser.banner = "Cached Static File Server"
      parser.on "-h", "--help", "Show this help" do
        puts parser
        exit 0
      end
      parser.on "-p PORT",
        "--port PORT",
        "bind the server to a port. Defaults to 12345" do |p|
        port = p.to_u16
      end
      parser.on "-d DIR",
        "--parent DIR",
        "specify the parent directory under which files will be served." do |dir|
        parent = dir
      end
      parser.on "-a ADDR", "--address ADDR", "bind to a given interface address" do |a|
        addr = a
      end
      # parser.on "-t TEMPLATE", "--on-not-found TEMPLATE", TEMPLATE_USAGE do |file|
      #   template = file
      # end
    end
    server = Server.new parent, port, addr
    # if template
    #   server.on_not_found do |request|
    #     ECR.render template
    #   end
    # end
    pp! parent, port, addr
    server
  end
end


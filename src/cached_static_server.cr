require "./log"

module CachedStaticServer
  TEMPLATE_USAGE = "\
    a template to render when a file is not found matching the requested \
    path. The template will have access to the received request as a \
    variable called `request'."

  class Server
    include Log

    def self.default_not_found_action(request : HTTP::Request) : String
      "No file found at #{request.path}"
    end

    property parent_dir : Path
    property port : UInt16
    property cache = {} of String => String
    property bind_address : String
    property not_found_action : Proc(HTTP::Request, String) = ->default_not_found_action(HTTP::Request)

    def initialize(parent_dir, port : Number, @bind_address)
      @parent_dir = Path.new parent_dir
      @port = port.to_u16
      read_files_into_cache
    end

    private def read_files_into_cache(dir : Path = @parent_dir)
      debug "scanning dir #{dir}"
      Dir.each_child dir.to_s do |file|
        next read_files_into_cache(dir / file) if File.directory? dir / file
        debug "caching file #{dir / file}"
        cache[(dir / file).to_s] = File.read dir / file
      end
    end

    def serve(request : HTTP::Request)
      if cached = cache[(parent_dir / request.path).to_s]?
        {200, cached}
      else
        {404, @not_found_action.call(request)}
      end
    end

    def on_not_found(&action : Proc(HTTP::Request, String))
      @not_found_action = action
    end
  end

  class CLI
    def self.build_server(args = ARGV)
      port, parent, addr = 12345, Dir.current, "0.0.0.0"
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
      server
    end
  end
end

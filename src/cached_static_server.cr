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
    property cache = {} of Path => Bytes
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
        fullpath = dir / file
        next read_files_into_cache fullpath if File.directory? fullpath
        debug "caching file #{fullpath}"
        File.open fullpath do |file|
          size = file.info.size
          buf = Bytes.new LibC.malloc(size).as(Pointer(UInt8)), size
          #  uninitialized, forever-living (no GC) pointer.
          #  these need to be kept around for the life of the
          #  program anyway, and we're about to fill
          #  in the buffer, so why bother zeroing it?
          read_count = file.read buf
          raise "read #{read_count} bytes from file #{fullpath} of size #{size}" if read_count != size
          cache[fullpath] = buf
        end
      end
    end

    def serve(request : HTTP::Request)
      if cached = cache[parent_dir / request.path]?
        {200, cached}
      elsif cached = cache[parent_dir / request.path / "index.html"]?
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
end

require "./log"
require "inotify"
require "./manual_memory_management"
require "./cli"

module CachedStaticServer
  TEMPLATE_USAGE = "\
    a template to render when a file is not found matching the requested \
    path. The template will have access to the received request as a \
    variable called `request'."

  class Server
    include Log
    include ManualMemoryManagement

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
      log "scanning dir %s", dir.to_s
      raise "tried to scan dir but was file at #{dir}" unless File.directory? path: dir
      watch_dir path: dir
      Dir.each_child dir.to_s do |file|
        fullpath = dir / file
        next read_files_into_cache fullpath if File.directory? fullpath
        read_in_one_file fullpath
      end
    end

    private def read_in_one_file(path : Path)
      log "caching file %s", path.to_s
      File.open path do |file|
        debug "file opened at ", path.to_s
        size = file.info.size
        buf = malloc size, path
        debug "buffer allocated"
        read_count = file.read buf
        raise "read #{read_count} bytes from file #{path} of size #{size}" if read_count != size
        debug "file read successfully"
        cache[path] = buf
        watch path
      rescue err
        LibC.free buf if buf
        raise err
      end
    end

    def watch(path : Path)
      debug "watching file %s", path.to_s
      Inotify.watch path.to_s do |event|
        debug "processing file event at %s", path.to_s
        case event.type
        when Inotify::Event::Type::DELETE, Inotify::Event::Type::DELETE_SELF
          log "delete event for %s received.", path.to_s
          if buf = cache.delete path
            debug "freeing buffer at 0x%X", buf.to_unsafe.address
            LibC.free buf
          end
        when Inotify::Event::Type::MODIFY
          log "modify event for %s received.", path.to_s
          update_file_at path
        end
      end
    end

    def watch_dir(path : Path)
      debug "watching directory #{path}"
      Inotify.watch path.to_s do |event|
        debug "processing directory event at %s", path.to_s
        evpath = event.path.try { |p| Path.new p } || path
        if name = event.name
          evpath /= name
        end
        debug "event path was #{evpath} and type was #{event.type}"
        case event.type
        when Inotify::Event::Type::CREATE
          if File.file? evpath
            log "caching new file at #{evpath}"
            update_file_at evpath
          elsif File.directory? evpath
            log "caching new directory at #{evpath}"
            read_files_into_cache evpath
          end
        when Inotify::Event::Type::DELETE
          if buf = cache.delete evpath
            debug "freeing buffer for #{evpath} at #{addr of: buf}"
            LibC.free buf
          end
        when Inotify::Event::Type::DELETE_SELF
          # delete any file under this path
          cache.reject! do |cache_path, buf|
            next unless cache_path > path
            log "clearing deleted file under #{path} at #{cache_path} from cache"
            LibC.free buf
            true
          end
          next
        else pp! event.type
        end
      end
    end

    def update_file_at(path)
      debug "file at #{path} was updated"
      File.open path do |file|
        debug "opened file at #{path}"
        size = file.info.size
        if buf = cache.delete path
          debug "overwriting existing buffer at #{addr of: buf}"
          if buf.size == size
            debug "same size, no need to reallocate"
            file.read buf
          else
            debug "reallocating buffer for file at #{path} from #{buf.size} to #{size} at #{addr of: buf}"
            buf = realloc buf, size
            debug "buffer is now at #{addr of: buf} through 0x#{(buf.to_unsafe.address + size).to_s base: 16}"
            file.read buf
          end
          cache[path] = buf
          log "updated cache for file at #{path}"
        else
          debug "file at #{path} not found in cache, reading in fresh."
          read_in_one_file path
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
end

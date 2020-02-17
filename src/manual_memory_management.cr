require "./log"

module ManualMemoryManagement
  include Log

  def malloc(size, file) : Bytes
    debug "allocating #{size} bytes for #{file}"
    ptr = LibC.malloc(size).as Pointer(UInt8)
    if ptr.null?
      raise Errno.new "\
            failed to allocate 0x#{size.to_s base: 16} bytes for #{file}"
    end
    debug "successfully returning #{size} allocated bytes at #{ptr.address.to_s base: 16}"
    Bytes.new pointer: ptr, size: size
  end

  def realloc(buf, size) : Bytes
    old_size = buf.size
    debug "reallocating buffer from #{old_size} to #{size} bytes at #{addr of: buf}"
    ptr = LibC.realloc(buf, size).as Pointer(UInt8)
    if ptr.null?
      raise Errno.new "\
            failed to reallocate buffer from 0x#{old_size.to_s base: 16} bytes \
            to 0x#{size.to_s base: 16} bytes"
    end

    debug "successfully returning #{size} allocated bytes at #{ptr.address.to_s base: 16}"
    Bytes.new pointer: ptr, size: size
  end
end

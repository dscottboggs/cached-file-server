module Log
  private def output(msg, *fmt, to log : IO)
    if fmt.empty?
      log.puts msg
    else
      log.puts msg % fmt
    end
  end

  # use VERBOSE=yes to enable verbose logging
  def log(msg, *fmt)
    {% if env "VERBOSE" %}
      output msg, *fmt, to: STDOUT
    {% end %}
  end

  # use DEBUG=yes to enable debug messages
  def debug(msg, *fmt)
    {% if env "DEBUG" %}
      output msg, *fmt, to: STDOUT
    {% end %}
  end

  # use WARNINGS=none to disable warnings
  def warn(msg, *fmt)
    {% if env("WARNINGS") == "none" %}
      output msg, *fmt, to: STDERR
    {% end %}
  end

  # use ERRORS=no to disable errors
  def error(msg, *fmt)
    {% if env("ERRORS") == "no" %}
      output msg, *fmt, to: STDERR
    {% end %}
  end

  def addr(of buf)
    "0x" + buf.to_unsafe.address.to_s base: 16
  end
end

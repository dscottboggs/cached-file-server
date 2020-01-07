module Log
  # use VERBOSE=yes to enable verbose logging
  def verbose?
    !ENV["VERBOSE"]?.nil?
  end

  # use DEBUG=yes to enable debug messages
  def debug?
    !ENV["DEBUG"]?.nil?
  end

  # use WARNINGS=none to disable warnings
  def no_warnings?
    ENV["WARNINGS"]?.nil?
  end

  # use ERRORS=no to disable errors
  def no_errors?
    ENV["ERRORS"]?.nil?
  end

  private def output(msg, *fmt, to log : IO)
    if fmt.empty?
      log.puts msg
    else
      log.puts msg % fmt
    end
  end

  def log(msg, *fmt)
    return unless verbose?
    output msg, *fmt, to: STDOUT
  end

  def debug(msg, *fmt)
    return unless debug?
    output msg, *fmt, to: STDOUT
  end

  def warn(msg, *fmt)
    return if no_warnings?
    output msg, *fmt, to: STDERR
  end

  def error(msg, *fmt)
    return if no_errors?
    output msg, *fmt, to: STDERR
  end
end

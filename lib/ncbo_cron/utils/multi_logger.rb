require 'omni_logger'

class MultiLogger < OmniLogger
  def flush()
    @loggers.each { |logger| logger.flush }
  end
end

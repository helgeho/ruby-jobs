require_relative '../logging/plain_logger'
require_relative '../logging/progress_logger'

module RubyJobs
  module JobBase
    module JobLogging
      def logger(type, logger_id=nil, logger_name=nil)
        @loggers ||= {}
        loggers_of_type = (@loggers[type] ||= {})

        logger_class = "#{type}Logger"
        logger_class[0] = logger_class[0].upcase

        base_name = job_name
        base_name += "_#{instance}" unless instance.nil? || instance.empty?
        logger_name ||= (logger_id ? "#{base_name}_#{logger_id}" : base_name)
        logger = (loggers_of_type[logger_id] ||= Logging.const_get(logger_class).new(logger_name))

        if block_given?
          yield logger
        end

        logger
      end

      def init_logger(id_or_name, name=nil, type=:plain)
        logger(type, id_or_name.to_sym, name || id_or_name.to_s)
      end

      def log(*messages)
        return logger(:plain) if messages.empty?
        return logger(:plain, messages.first).log *messages.drop(1) if messages.first.is_a? Symbol || messages.first.nil?
        logger(:plain).log *messages
      end

      def progress(*messages, &block)
        return logger(:progress) if messages.empty?
        return logger(:progress, messages.first).log *messages.drop(1) if messages.first.is_a? Symbol
        block_given? ? logger(:progress).log(*messages, &block) : logger(:progress).log(*messages)
      end
    end
  end
end
module RubyJobs
  module Logging
    class ProgressLogger < PlainLogger
      PATH = "log/progress"

      def initialize(*names)
        super
        @path = PATH
        @start = 0.0
        @end = 100.0
        @progress = 0.0
        @progress_key = :count
        @print_timestamp = true
      end

      attr_accessor :progress, :progress_key
      attr_reader :start, :end

      def start=(value)
        @start = value.to_f
      end

      def end=(value)
        @end = value.to_f
      end

      def log(progress, *message)
        if progress.is_a?(Hash) && progress.include?(@progress_key)
          @progress = (progress[@progress_key].to_f - @start) / (@end - @start) * 100.0
          message = ([progress] + message)
        elsif !progress.is_a?(String) && progress.respond_to?(:to_f)
          @progress = (progress.to_f - @start) / (@end - @start) * 100.0
          message = [progress] if message.empty?
        else
          message = ([progress] + message)
        end

        if @print_timestamp
          @print_timestamp = false
          messsage = super @progress.to_i, "%", timestamp, "-", *message
          @print_timestamp = true
        else
          messsage = super @progress.to_i, "%", *message
        end

        yield @progress, message if block_given?

        messsage
      end
    end
  end
end
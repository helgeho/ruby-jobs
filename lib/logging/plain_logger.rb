require 'fileutils'

module RubyJobs
  module Logging
    class PlainLogger
      DEFAULT_PATH = "log/plain"

      def initialize(*names)
        @names = names.compact
        @path = DEFAULT_PATH
        @time_prefix = true
        @print_timestamp = false
        @write_file = true
      end

      attr_accessor :path, :time_prefix, :separator, :extension, :print_timestamp

      def file(&block)
        File.open(file_path, 'a+', &block)
      end

      def exist?
        File.exist? file_path
      end

      def log_dir
        dir = File.expand_path(@path, APP_ROOT)
        FileUtils.mkpath dir
        dir
      end

      def file_path
        File.join(log_dir, file_name)
      end

      def file_name
        return @file_name if @file_name

        file_name = ""
        if @time_prefix
          file_name << Time.now.strftime("%Y%m%d%H%M%S")
          file_name << "_"
        end
        file_name << @names.map{|w| w.to_s.gsub(/^[\W_]*|[\W_]*$/, '').gsub(/[\W_]+/, '_')}.join("_")
        file_name << ".#{extension}" if extension
        @file_name = file_name
      end

      def puts(message)
        if @puts
          if @clear_puts
            @puts.call ((@last_message ? (("\b" * @last_message.length) + message) : message)), file_name
          else
            @puts.call @separator if @separater
            @puts.call message, file_name
          end
          @last_message = message
        end

        if @write_file
          file do |file|
            file.puts @separator if @separater
            file.puts message
          end
        end
      end

      def def_puts(write_file=false, clear=false, &block)
        @clear_puts = clear
        @write_file = write_file
        if block_given?
          @puts = block
        else
          @puts = clear ? Proc.new{|m| print m} : Proc.new{|m| Kernel.puts m}
        end
      end

      def timestamp
        "[#{Time.now.strftime "%Y-%m-%d %H:%M:%S"}]"
      end

      def log(*message)
        message = message.map(&:to_s).join(" ")
        message = "#{timestamp} - #{message}" if @print_timestamp

        puts message

        message
      end
    end
  end
end
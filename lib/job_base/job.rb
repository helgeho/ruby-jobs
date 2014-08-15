require_relative 'job_logging'

module RubyJobs
  module JobBase
    class Job
      include JobLogging

      @@bootstrapped = false
      @@requires_rails = nil
      @@puts_overridden = false

      def initialize(defaults=nil)
        @values = self.class.defaults.dup
        @values.merge! defaults unless defaults.nil?
      end

      def instance
        @instance
      end

      def job_name
        self.class.name.gsub(/([^$])([A-Z])/, '\1_\2').downcase # underscore without rails
      end

      def run(values=nil, &block)
        @running = true

        puts_block = @puts_block || self.class.puts_block
        if puts_block && !@@puts_overridden
          @@puts_overridden = true
          @puts_overridden = true

          Kernel.send(:define_method, :puts) do |m|
            puts_block.call m
            nil
          end
        end

        @values.merge! values unless values.nil?
        if block_given?
          block_values = instance_exec @values, &block
          @values.merge! block_values if block_values.is_a? Hash
        end

        result = instance_exec @values, &self.class.block

        @running = false

        if @puts_overridden
          Kernel.send :remove_method, :puts
          Kernel.send :alias_method, :puts, :_puts
          @puts_overridden = false
          @@puts_overridden = false
        end

        result
      end

      class << self
        def initialize
          unless @initialized
            @initialized = true
            @defaults = {}
            @default_blocks = {}
            @instance_hashes = {}
            @instance_blocks = {}
            @loaded_rails = false
            load_rails if @@requires_rails || @@requires_rails.nil?
          end
        end

        def defaults
          default_blocks = @default_blocks.dup
          @default_blocks = {}
          default_blocks.each do |k,b|
            if k.nil?
              b.call.each do |key, value|
                @defaults[key] = value
              end
            else
              @defaults[k] = b.call
            end
          end
          @defaults
        end

        attr_reader :instance_hashes, :instance_blocks, :puts_block, :block

        def run(instance_or_values=nil, &block)
          initialize
          if instance_or_values.is_a? Hash
            values = instance_or_values
            job = self.new
            job.run values, &block
          else
            instance = instance_or_values
            run = true
            if block_given?
              @block = block
              if !@@bootstrapped && (!defined?(Rails) || @loaded_rails)
                instance = ARGV.first || instance
                @@bootstrapped = true
              else
                run = false
              end
            end

            if run
              job = self.new
              job.load_instance instance.to_sym if instance
              job.run
            end
          end
        end

        def rails
          load_rails
          return yield Rails if block_given?
          Rails
        end

        def load_rails
          initialize
          begin
            load_rails = require File.expand_path('config/boot', APP_ROOT)
            load_rails &&= require APP_PATH
            if load_rails
              puts "loading rails..."
              Rails.application.require_environment!
              return @loaded_rails = true
            end
            false
          rescue Exception
            false
          end
        end

        def instance(name=nil, hash=nil, &block)
          initialize
          if name
            @instance_hashes[name] = hash unless hash.nil?
            @instance_blocks[name] = block
          end
        end

        def default(key=nil, value=nil, &block)
          initialize
          if value.nil? && block_given?
            @default_blocks[key] = block
          else
            if value.nil? && key.is_a?(Hash)
              key.each do |key, value|
                @defaults[key] = value
              end
            else
              @defaults[key] = value
            end
          end
        end

        def requires_rails=(value)
          @@requires_rails ||= value
        end

        def define_puts(&block)
          initialize
          @puts_block = block
        end

        def const_missing(const)
          initialize
          value = defaults[const.to_s.downcase.to_sym]
          value.nil? ? Object.const_get(const) : value
        end
      end

      def method_missing(method, *args, &block)
        if method.to_s.end_with? "="
          @values[method.to_s[0..-2].to_sym] = args.first
        elsif @values.include? method
          @values[method]
        else
          super
        end
      end

      def const_missing(const)
        @values[const.to_s.downcase.to_sym]
      end

      def define_puts(&block)
        if block_given?
          @puts_block = block
          if @running && (!@@puts_overridden || @puts_overridden)
            @@puts_overridden = true
            @puts_overridden = true
            Kernel.send(:define_method, :puts) do |m|
              block.call m
              nil
            end
          end
        end
      end
      alias_method :def_puts, :define_puts

      def _puts(message)
        if @puts_overridden
          super
          message
        else
          puts(message)
        end
      end

      def load_instance(instance, values={})
        @values.merge! self.class.instance_hashes[instance].merge(values) if self.class.instance_hashes.include?(instance)
        block = self.class.instance_blocks[instance]
        if block
          block_values = instance_exec @values, &block
          @values.merge! block_values if block_values.is_a? Hash
        end
        @instance = instance
      end

      Kernel.send :alias_method, :_puts, :puts
    end
  end
end

require 'open3'

require 'buchungsstreber/cli/app'

module Buchungsstreber
  module CLI
    class Runner
      # Allow everything fun to be injected from the outside while defaulting to normal implementations.
      def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
        @argv, @stdin, @stdout, @stderr, @kernel = argv, stdin, stdout, stderr, kernel

        unless kernel.respond_to?(:exec)
          kernel.send(:define_singleton_method, :exec) do |cmd, *params|
            rc = nil
            Open3.popen3(cmd, *params) do |in_, out_, err_, t|
              out_reader = Thread.new { STDERR.puts stdout.write(out_.read) }
              err_reader = Thread.new { STDERR.puts stderr.write(err_.read) }
              in_writer = Thread.new { while s = stdin.gets("\n"); STDERR.puts(s); in_.write(s); end }
              STDOUT.puts([1, out_reader, err_reader, in_writer].inspect)
              STDERR.puts("waiting for threads to exit")
              #[out_reader, err_reader, in_writer].each { |th| th.join }
              #STDOUT.puts([2, out_reader, err_reader, in_writer].inspect)
              rc = t.value.exitstatus
              #STDOUT.puts([3, out_reader, err_reader, in_writer].inspect)
            end
            STDERR.puts("exiting exec")
            kernel.exit(rc)
          end
        end
      end

      def execute!
        exit_code = begin
                      # Thor accesses these streams directly rather than letting them be injected, so we replace them...
                      $stderr = @stderr
                      $stdin = @stdin
                      $stdout = @stdout
                      Buchungsstreber::CLI::App.class_variable_set(:@@kernel, @kernel)

                      # Run our normal Thor app the way we know and love.
                      Buchungsstreber::CLI::App.start(@argv)

                      # Thor::Base#start does not have a return value, assume success if no exception is raised.
                      0
                    rescue StandardError => e
                      # The ruby interpreter would pipe this to STDERR and exit 1 in the case of an unhandled exception
                      b = e.backtrace
                      @stderr.puts("#{b.shift}: #{e.message} (#{e.class})")
                      @stderr.puts(b.map { |s| "\tfrom #{s}" }.join("\n"))
                      1
                    rescue SystemExit => e
                      e.status
                    ensure
                      # TODO: reset your app here, free up resources, etc.
                      # Examples:
                      # MyApp.logger.flush
                      # MyApp.logger.close
                      # MyApp.logger = nil
                      #
                      # MyApp.reset_singleton_instance_variables

                      Buchungsstreber::CLI::App.class_variable_set(:@@kernel, Kernel)
                      # ...then we put the streams back.
                      $stderr = STDERR
                      $stdin = STDIN
                      $stdout = STDOUT
                    end

        # Proxy our exit code back to the injected kernel.
        @kernel.exit(exit_code)
      end
    end
  end
end
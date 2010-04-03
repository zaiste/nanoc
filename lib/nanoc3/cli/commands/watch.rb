# encoding: utf-8

module Nanoc3::CLI::Commands

  class Watch < Cri::Command

    def name
      'watch'
    end

    def aliases
      [ ]
    end

    def short_desc
      'start the watcher'
    end

    def long_desc
      'Start the watcher. When a change is detected, the site will be ' \
      'recompiled.'
    end

    def usage
      "nanoc3 watch"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      require 'fssm'

      # TODO send growl notifications
      # # --image misc/success-icon.png
      # system('growlnotify', '-m', 'Compilation completed')
      # # --image misc/error-icon.png
      # system('growlnotify', '-m', 'Compilation failed')

      # Define rebuilder
      rebuilder = lambda do |base, filename|
        # Notify
        if filename
          print "Change detected to #{filename}; recompiling… ".make_compatible_with_env
        else
          print "Watcher started; compiling the entire site… ".make_compatible_with_env
        end

        # Recompile
        start = Time.now
        site = Nanoc3::Site.new('.')
        site.load_data
        begin
          site.compiler.run

          puts "done in #{((Time.now - start)*10000).round.to_f / 10}ms"
        rescue Exception => e
          puts
          @base.print_error(e)
          puts
        end
      end

      # Rebuild once
      rebuilder.call(nil,nil)

      # Get directories to watch
      # FIXME needs something more intelligent and customizable
      dirs_to_watch = %w( content layouts lib )

      # Watch
      puts "Watching for changes…".make_compatible_with_env
      watcher = lambda do
        update(&rebuilder)
        delete(&rebuilder)
        create(&rebuilder)
      end
      monitor = FSSM::Monitor.new
      dirs_to_watch.each do |dir|
        monitor.path(dir, '**/*', &watcher)
      end
      monitor.run
    end

  end

end

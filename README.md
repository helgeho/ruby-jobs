ruby-jobs
======
Get your jobs done.
Simple scripts or complete experiments.
Either with or without rails.

Installation
-------
ruby-jobs is available on RubyGems.org: [https://rubygems.org/gems/ruby-jobs](https://rubygems.org/gems/ruby-jobs)
You can install it by calling

`gem install ruby-jobs`

Or by adding it to your Gemfile.

Example
-------

<pre>
require 'ruby-jobs'

# Call it with 'ruby app/jobs/greet_the_world.rb planet' from the application folder
# or from within another job by invoking GreetTheWorld.run :planet or TestJob.run {:subject => 'earth'}.
# You can even create an instance, job = GreetTheWorld.new :greeting => 'How are you',
# load a job instance job.load_instance :planet, {:period => '?'}
# and run it with your custom configurations job.run :times => 1.
class GreetTheWorld < RubyJobs::JobBase::Job
  self.requires_rails = false # this job does not require rails, skips the loading to save time

  default :greeting, 'Hello'
  default :subject, 'world'
  default :period, '.'
  default :times, 10
  default do
    # here you can execute code and use the Rails constant (if not turned off as above)
    {
        :rails_loaded => !(Rails rescue nil).nil?
    }
  end

  instance :default_instance, :period => '!'

  instance :planet, :subject => 'planet', :period => '!!'

  instance :batman do
    # this block will only be executed for this instance
    greeting = "Na" * 10
    {
        :greeting => greeting,
        :subject => 'Batman'
    }
  end

  run :default_instance do
    log 'starting'
    log "Rails loaded? #{rails_loaded}"

    # define an additional logger
    init_logger :results, "Hello_#{instance}", :plain # :plain is default, other option would be :progress
    logger(:plain, :results).time_prefix = false # turn time file prefix off
    logger(:plain, :results).def_puts true # in addition to the log file, output results to the console
    # log(:id) and progress(:id) are shortcuts for logger(:plain/:progress, :id)

    # if you do not want the default output, define you own 'puts'
    progress.def_puts false, true do |m|
      # do not log progress to a file in log/progress (false)
      # overwrite progress messages on the console (true)
      print m
      # this is the default, you can actually omit the blog
      # (progress.def_puts(false, true) would do as well)
    end

    progress.start = 0
    progress.end = times
    progress.progress_key = :count # this is default, you could omit it

    # creating greetings
    greetings = []
    (0..times).each do |i|
      result = {:count => i, :greeting => "#{greeting} #{subject}#{period}"}

      progress i, "Greeted already #{i} times"
      progress result # logging progress by using the progress key

      greetings << result
    end

    # logging results
    greetings.each do |greeting|
      log :results, greeting[:greeting]
    end

    log 'done'

    greetings # return results, for instance to use in another job
  end
end
</pre>
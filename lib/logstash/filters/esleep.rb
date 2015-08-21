# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# Sleep a given amount of time. This will cause logstash
# to stall for the given amount of time. This is useful
# for rate limiting, etc.
#
class LogStash::Filters::Esleep < LogStash::Filters::Base
  config_name "esleep"

  # The length of time to sleep, in seconds, for every event.
  #
  # This can be a number (eg, 0.5), or a string (eg, `%{foo}`)
  # The second form (string with a field value) is useful if
  # you have an attribute of your event that you want to use
  # to indicate the amount of time to sleep.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       esleep {
  #         # Sleep 1 second for every event.
  #         sleeptime => "1"
  #       }
  #     }
  config :sleeptime, :validate => :number, :default => 1

  # Sleep on every N'th. This option is ignored in replay mode.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       esleep {
  #         sleeptime => "1"   # Sleep 1 second
  #         every => 10   # on every 10th event
  #       }
  #     }
  config :every, :validate => :number, :default => 1


  # Forces sleep after a certain amount of elapsed time if 
  # hasn't reached n'th amount.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       esleep {
  #         sleeptime => "1"   # Sleep 1 second
  #         every => 10   # on every 10th event
  #         timelimt => 10 # or sleeps every 10 seconds
  #       }
  #     }
  config :timelimit, :validate => :number, :default => 0

  # Initialization of the plugin
  public
  def register
    require "atomic"
    @count = Atomic.new(0)
    @elapsed_time = Atomic.new(0)
    @check_time = (@timelimit != 0)
    @timelimit = @timelimit
    @last_time = Time.now.utc.to_i
  end # def register

  # counts the number of messages that came through
  public
  def filter(event)
    return unless filter?(event)
    @count.update {|v| v + 1 }
    if @count.value >= @every
      start_sleep
    end
    filter_matched(event)
  end # def filter

  # uses flush to periodically check time so flush must be on
  public
  def periodic_flush
    true
  end # periodic_flush

  # Checks the time to see if the process has timedout, thus forcing a sleep
  public
  def flush(options = {})
    curr_time = Time.now.utc.to_i
    @elapsed_time.update {|v| v + (curr_time - @last_time)}
    @last_time = curr_time
    if @timelimit <= @elapsed_time.value && @check_time
      start_sleep
    end
    return
  end # flush

  # The actual sleep function. Resets all counters and timers
  def start_sleep
    # This case statement is legacy from the original sleep code
    @sleep_on_time = false
    @elapsed_time.update { |v| 0 } 
    @last_time += @sleeptime
    @count.update { |v| 0 }
    @logger.debug? && @logger.debug("Sleeping", :delay => @sleeptime)
    sleep(@sleeptime)
  end # start_sleep
end # class LogStash::Filters::esleep

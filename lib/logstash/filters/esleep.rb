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
  #       sleep {
  #         # Sleep 1 second for every event.
  #         time => "1"
  #       }
  #     }
  config :time, :validate => :string

  # Sleep on every N'th. This option is ignored in replay mode.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       sleep {
  #         time => "1"   # Sleep 1 second
  #         every => 10   # on every 10th event
  #       }
  #     }
  config :every, :validate => :number, :default => 1

  config :timelimit, :validate => :number, :default => 0

  public
  def register
    require "atomic"
    if @time.nil?
      raise ArgumentError, "Missing required parameter 'time' for input/eventlog"
    end
    @count = Atomic.new(0)
    @elapsed_time = Atomic.new(0.0)
    @timelimit = - @timelimit
    @last_sleep_time = Time.now.to_i
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    @count.update {|v| v + 1 }
    clock = event.timestamp.to_f
    if @last_clock
        @elapsed_time.update { |v| v - (clock - @last_clock) } #stores elapsed_time as a negative
    end
    if @elapsed_time.value <= @timelimit
      est_curr_time = @last_sleep_time - @timelimit
      act_curr_time = Time.now.to_i
      if est_curr_time > act_curr_time
        @elapsed_time.update { |v|  - (act_curr_time - @last_sleep_time) }
      else
        start_sleep(event)
      end
    end
    if @count.value >= @every
      start_sleep(event)
    end
    @last_clock = clock
    filter_matched(event)
  end # def filter

  def start_sleep(event)
    case @time
      when Fixnum, Float; time = @time
      when nil;
      else; time = event.sprintf(@time).to_f
    end
    @elapsed_time.update { |v| 0 } 
    @count.update { |v| 0 }
    @last_clock = nil
    @logger.debug? && @logger.debug("Sleeping", :delay => time)
    @last_sleep_time = Time.now.to_i + time
    sleep(time)
  end # reset
end # class LogStash::Filters::Sleep

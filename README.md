#Logstash Plugin Filter - ESleep

This is a throttling plugin for logstash. It will force logstash to sleep for a specified amount of time after either a) processing a certain number of messages or b) spending a certain amount of time processing those messages

Following the lead of LogStash, this plugin is completely free and fully open source. The license is Apache 2.0 (I think?). 

##Disclaimer

This plugin is essentially a stripped down and modified version of the LogStash plugin [sleep](https://github.com/logstash-plugins/logstash-filter-sleep). 

If you read through the code, it copies large portions of code from the metric code; I do not claim to be the author of alot of the code. I simply jury-rigged the metrics plugin code to fit my usecase to run some tests. I do not believe I violate any of the licenses of the plugin/lib, but if either parties are upset, feel free to email [me](kelvinfann@outlook.com). I only put this up because I figured some other user might also need to have use for what I wrote

##Credit
This plugin utilizes the following libraries:
  - [Atomic library](https://github.com/ruby-concurrency/atomic)
 

##Install
You install this plugin as you would install all logstash plugins. Here is a [guide](https://www.elastic.co/guide/en/logstash/current/_how_to_write_a_logstash_filter_plugin.html#_test_installation_3) Use the test installation 

##Config

Esleep is, in many ways, a simplified version of the sleep plugin. The configs that should concern you are:

  - `sleeptime`: the amount of time you want to sleep the logstash process 
  - `every`: the number of messages to process before sleeping
  - `timelimit`: forces sleep after a certain amount of elapsed time if hasn't reached the 'every' amount of messages

##Example

Simple stdin/out example

logstash config:

```
input{
	stdin{}
}
filter{
	esleep{
		sleeptime => 1 # Sleep 1 second
		every => 10 # on every 10th event
		timelimit => 20 # or when 20 seconds has elapsed. Which ever first
	}
}
output{
	stdout{}
}
```

Note that after the logstash process sleeps the every and timelimit are both reset.





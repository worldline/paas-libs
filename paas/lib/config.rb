$configFile = "/etc/paas/configProxy.conf"

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'singleton'
require 'optparse'

module Awlpaas
  class Config
    include Singleton

		attr_reader :usernameBroker, :passwordBroker, :domainName, :usernameMcollective,
						:passwordMcollective, :serveurMcollective, :portMcollective, :configured,
						:topicRepli, :topicResponse, :confMCOProxy, :logFile, :brokerIp, :portMongo

    def initialize
      @configured = false
    end

		def getConffilename
      parser = OptionParser.new
      parser.on("--config CONFIG", "-c", "Config file") do |f|
        configfile = f
      end
      configfile = $configFile unless configfile
			configfile
		end

    def loadconfig
			configfile = getConffilename
      set_config_defaults(configfile)

      if File.exists?(configfile)
        File.open(configfile, "r").each do |line|
          # strip blank spaces, tabs etc off the end of all lines
          line.gsub!(/\s*$/, "")
          unless line =~ /^#|^$/
            if (line =~ /(.+?)\s*=\s*(.+)/)
              key = $1
              val = $2

              case key
                when "usernameBroker"
                  @usernameBroker = val
                when "passwordBroker"
                  @passwordBroker = val
                when "domainName"
                  @domainName = val
                when "usernameMcollective"
                  @usernameMcollective = val
                when "passwordMcollective"
                  @passwordMcollective = val
                when "serveurMcollective"
                  @serveurMcollective = val
                when "portMcollective"
                  @portMcollective = val
								when "topicResponse"
									@topicResponse = val
								when "topicRepli"
									@topicRepli = val
								when "confMCOProxy"
									@confMCOProxy = val
								when "logFile"
									@logFile = val
								when "brokerIp"
									@brokerIp = val
								when "portMongo"
									@portMongo = val
                else
                  raise("Unknown config parameter #{key}")
              end
            end
          end
        end
        @configured = true
      else
        raise("Cannot find config file '#{configfile}'")
      end
    end

    def set_config_defaults(configfile)
			@usernameBroker = String.new
			@passwordBroker = String.new
			@domainName = String.new
			@usernameMcollective = "mcollective"
			@passwordMcollective = "marionette"
			@serveurMcollective = "localhost"
			@portMcollective = 61613
			@topicResponse = /topic/mcollectiveReplyRepli
			@topicRepli = /topic/mcollectiveOOAgentRepli
			@confMCOProxy = '/etc/mcollective/clientDmz.cfg'
			@logFile = '/var/log/paas/configProxy.log'
			@brokerIp = "127.0.0.1"
			@portMongo = "27017"
    end

  end
end

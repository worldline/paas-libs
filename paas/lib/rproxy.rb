#!/usr/bin/ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'uri'
require 'logger'
require 'mcollective'
require 'paasexceptions'
require 'config'
include MCollective::RPC
$confFile = '/etc/mcollective/clientDmz.cfg'

module Awlpaas

	class Rproxy
		def initialize()
      Config.instance.loadconfig unless Config.instance.configured
      $paasConfig = Config.instance

			@options = Hash.new
			@options[:config] = $paasConfig.confMCOProxy
			@mc = rpcclient("rproxy", :options => @options)
		end

		def configureAppli(appName, domainName, ipPorts, aliases)
			begin
				@mc.progress = false
				@mc.timeout = 2
			# mco rpc --dt 1 -j -v --agent rproxy --action conf --arg "appname=#{appName}" --arg "appalias=#{aliases}" --arg "args=#{ipPorts}"
				args = Hash.new
        args[:appname] = appName
        args[:domainname] = domainName
				if aliases.kind_of?(Array) == true && aliases.empty? == false
					args[:appalias] = aliases.join(' ')
				end
				if ipPorts.kind_of?(Array) == true &&  ipPorts.empty? == false
					args[:args] = ipPorts.join(' ')
				else
					 args[:args] = " "
				end
				response =  @mc.conf(args)

				response.each do |resp|
					unless resp[:data][:exitcode] == "OK"
    				raise(AwlpaasRproxyException, "Error: configureAppli: #{resp[:statusmsg]}")
					end
				end
				return (response)
			rescue Exception => e
				raise(AwlpaasRproxyException, "Error configureAppli: #{e}")
			end
		end

		def unconfigureAppli(appName, domainName)
			begin
				@mc.discover
				@mc.progress = false
				@mc.timeout = 2
			# mco rpc --dt 1 -j -v --agent rproxy --action unconfigure --arg "appname=#{appName}"
				args = Hash.new
        args[:appname] = appName
        args[:domainname] = domainName
				response =  @mc.send('unconfigure', args)

				response.each do |resp|
					unless resp[:data][:exitcode] == "OK"
    				raise(AwlpaasRproxyException, "Error: unconfigureAppli: #{resp[:statusmsg]}")
					end
				end
			rescue Exception => e
				raise( AwlpaasRproxyException, "Error unconfigureAppli: #{e}")
			end
		end

	end
end

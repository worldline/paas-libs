#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'uri'
require 'logger'
require 'mcollective'
require 'resolv'
require 'paasexceptions'
include MCollective::RPC

module Awlpaas

	class Node
		def initialize()
			@mc = rpcclient("rpcutil")
      @mco = rpcclient("openshift")
		end

		def getCpuLoad(node)
			#mco rpc rpcutil get_fact fact=cpuload
			begin
				@mc.discover :nodes => ["#{node}"]
				@mc.progress = false
				@mc.timeout = 2
				response =  @mc.get_fact(:fact => "cpuload")
				if response.length != 0
					retour = response[0][:data][:value] # one reponse only PTP
				end
				return (retour)
			rescue MCollective::RPCError => e
				#@mc.disconnect
				raise(AwlpaasNodeException, "Error getCpuLoad: #{e}")
			end
		end

		def getMemFree(node)
			#mco rpc rpcutil get_fact fact=memoryfree
			begin
				@mc.discover :nodes => ["#{node}"]
				@mc.progress = false
				@mc.timeout = 2
				response =  @mc.get_fact(:fact => "memoryfree")
				if response.length != 0
					retour = response[0][:data][:value] # one reponse only PTP
				end
				return (retour)
			rescue MCollective::RPCError => e
				raise(AwlpaasNodeException, "Error: getMemFree: #{e.backtrace.inspect}")
			end
		end

		def showAppPrimaryPort(appName, domainName, uuid, cartridge)
			begin
				# @mco.discover :nodes => ["#{node}"]
				@mco.progress = false
				@mco.timeout = 2
        args = Hash.new
        args[:cartridge] = cartridge
        args[:action] = "show-port"
        args[:args] = "#{appName} #{domainName} #{uuid}"
        response =  @mco.cartridge_do(args)
				primaryPort = 0
				primaryHost = ""
				myDns = Resolv::DNS.new(:nameserver => ["#{$paasConfig.brokerIp}"], :search => ["#{domainName}"],
                :ndots => 1)

        response.each do |resp|
          if resp[:data][:exitcode] == 0
						primaryPort = resp[:data][:output].gsub(/\n/,'').gsub(/^.*PROXY_PORT=([0-9]*)CART_DATA:.*$/, '\1')
						primaryHost = myDns.getaddress(resp[:sender])
          end
				end
				if primaryPort == 0
					raise(AwlpaasNodeException, "Error: showAppPrimaryPort: Information not found")
				else
					return "#{primaryHost}:#{primaryPort}"
				end
      rescue Resolv::ResolvError => re
        raise(AwlpaasNodeException, "Dns resolution error : showAppPrimaryPort:  #{re}")
			rescue Exception => e
				#@mc.disconnect
				raise(AwlpaasNodeException, "Error: showAppPrimaryPort:  #{e}")
      end
			#mco rpc --dt 1 -j -v  --agent openshift --action cartridge_do --arg "cartridge=php-5.3" --arg "args='phptest' 'openshift' '43b9ae67113340c38d64987e58884096'" --arg "action=show-port"
		end

		end
end

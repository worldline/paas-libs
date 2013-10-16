#!/usr/bin/env ruby

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'uri'
require 'logger'
require 'rest-client'
require 'json'
require 'base64'
require 'config'
require 'paasexceptions'
require 'resolv'
require 'mongo'
include Mongo

$baseUrl='http://%s/broker/rest'
$baseUrlLocal='http://%s:8080/broker/rest'
$appUrl='/domains/%s/applications'
$aliasUrl='/domains/%s/applications/%s'
$eventUrl='/domains/%s/applications/%s/events'
$cartridges_url='/cartridges'
$domainUrl='/domains'
$mongoDb="openshift_broker_dev"
$mongoCollUsers="cloud_users"
$mongoCollApps="applications"
$mongoCollDom="domains"

module Awlpaas

	class Broker
		def initialize(namespace, appName)
			Config.instance.loadconfig unless Config.instance.configured
    	$paasConfig = Config.instance

			@namespace = namespace
			@appName = appName
			listUserByDomain()
			#@authent64 = Base64.encode64("#{username}:#{password}").delete("\n")
		end

    def addGear(verbose, uuid)
        Log.info("addGear: #{@appName} #{@namespace} #{uuid}")
        res=`add-gear -n #{@namespace} -a #{@appName} -u #{uuid}`
        Log.debug("addGear: exit: #{$?}  stdout: #{res}")
    end

    def removeGear(verbose, uuid)
        Log.info("removeGear: #{@appName} #{@namespace} #{uuid}")
        res=`remove-gear -n #{@namespace} -a #{@appName} -u #{uuid}`
        Log.debug("removeGear: exit: #{$?}  stdout: #{res}")
    end

		def listDomains()
			baseUrl = "#{$baseUrl % "localhost:8080"}#{$domainUrl}"
			request = RestClient::Request.new(:method => :get, :url => baseUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => {} )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				domains = Array.new
				for domain in result["data"]
					domains.push(domain["id"])
				end
				return domains
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "Http error: #{e.http_code}")
			end

		end

		def listApps()
			baseUrl = "#{$baseUrl % "localhost:8080"}#{$appUrl % @namespace}"
			request = RestClient::Request.new(:method => :get, :url => baseUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => {} )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				apps = Array.new
				for app in result["data"]
					apps.push(app["name"])
				end
				return apps
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "listApps: The request failed with http_code: #{e.http_code}")
			rescue RestClient::Exception => e
				raise(AwlpaasBrokerException, "listApps: The request failed with exception: #{e.to_s}")
			end
		end

		def showWebCartridge()
			aliasUrl = "#{$baseUrl % "localhost:8080"}#{$aliasUrl % [ @namespace, @appName ]}"
			request = RestClient::Request.new(:method => :get, :url => aliasUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => {} )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				return result["data"]["framework"]
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "listApps: The request failed with http_code: #{e.http_code}")
			rescue RestClient::Exception => e
				raise(AwlpaasBrokerException, "listApps: The request failed with exception: #{e.to_s}")
			end
		end

		def listAliasesLocal()
			aliasUrl = "#{$baseUrlLocal % "localhost:8080"}#{$aliasUrl % [ @namespace, @appName ]}"
			request = RestClient::Request.new(:method => :get, :url => aliasUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => {} )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				return result["data"]["aliases"]
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "listAliasesLocal: The request failed with http_code: #{e.http_code}")
			rescue RestClient::Exception => e
				raise(AwlpaasBrokerException, "listAliasesLocal: The request failed with exception: #{e.to_s}")
			end
		end

		def listAliases()
			aliasUrl = "#{$baseUrl % "localhost:8080"}#{$aliasUrl % [ @namespace, @appName ]}"
			request = RestClient::Request.new(:method => :get, :url => aliasUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => {} )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				return result["data"]["aliases"]
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "listAliases: The request failed with http_code: #{e.http_code}")
			rescue RestClient::Exception => e
				raise(AwlpaasBrokerException, "listAliases: The request failed with exception: #{e.to_s}")
			end
		end

		def listUserByDomain()
			utilisateur = "admin" # Trivial init
			begin
				@client = MongoClient.new($paasConfig.brokerIp, $paasConfig.portMongo)
				@db = @client[$mongoDb]
				@coll = @db[$mongoCollDom]
				@curseur =  @coll.find({:namespace => @namespace}, {})
				if @curseur.count != 0
					@ownId =  @curseur.next_document["owner_id"]
					@coll = @db[$mongoCollUsers]
					utilisateur = @coll.find({:_id => @ownId}, {}).next_document["login"]
				end
				@client.close
			rescue Exception => be
				raise(AwlpaasBrokerException, "listUserByDomain: The request failed with exception: #{be.to_s}")
			end
			@user = utilisateur
		end

		def isAppScalable()
			ipWeb = ""
			isScalable = true
			begin
				@client = MongoClient.new($paasConfig.brokerIp, $paasConfig.portMongo)
				@db = @client[$mongoDb]
				@coll = @db[$mongoCollDom]
				@ident =  @coll.find({:namespace => @namespace}, {}).next_document["_id"]
				@coll = @db[$mongoCollApps]
				@coll.find({:scalable => false, :name => @appName, :domain_id => @ident}, :fields => ["group_instances"]).each do |row|
					@serverName = row["group_instances"][0]['gears'][0]['server_identity']
					isScalable = false
				end
				@client.close
				if isScalable == false
					myDns = Resolv::DNS.new(:nameserver => ["#{$paasConfig.brokerIp}"], :search => [@namespace],
									:ndots => 1)
					ipWeb = myDns.getaddress("#{@serverName}")
        end
      rescue Resolv::ResolvError => re
        raise(AwlpaasBrokerException, "isAppScalable: Dns Resolution Error:  #{re}")
			rescue Exception => e
				raise(AwlpaasBrokerException, "isAppScalable: Error: #{e.to_s}")
			end
			return isScalable, ipWeb.to_s
		end

		def showPrimaryPort()
			showPortUrl = "#{$baseUrl % "localhost:8080"}#{$eventUrl % [ @namespace, @appName ]}"
			params = {
        'broker_auth_key' => File.read("/tmp/auth_key"),
        'broker_auth_iv' => File.read("/tmp/auth_iv")
			}
			params['event'] = 'show-port'
			request = RestClient::Request.new(:method => :post, :url => showPortUrl, :timeout => 600,
				:headers => {:accept => 'application/json', "User-Agent" => 'rhc', "X-Remote-User" => "#{@user}"},
				:payload => params )

			begin
				response = request.execute()
				if 300 <= response.code
					raiseresponse
				end
				result = JSON.parse(response)
				return result["data"]
			rescue RestClient::ExceptionWithResponse => e
				raise(AwlpaasBrokerException, "showPrimaryPort: The request failed with http_code: #{e.http_code}")
			rescue RestClient::Exception => e
				raise(AwlpaasBrokerException, "showPrimaryPort: The request failed with exception: #{e.to_s}")
			end
		end

	end
end

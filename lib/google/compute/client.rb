# Copyright 2013 Google Inc. All Rights Reserved.
#
# Copyright 2013 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'google/api_client'
require 'multi_json'
require 'google/compute/resource_collection'

module Google
  module Compute
    class Client

      DEFAULT_FILE = '~/.google-compute.json'

      attr_reader :dispatcher

      def initialize(authorization, project, credential_file)
        api_client = Google::APIClient.new(:application_name=>'google-compute-ruby-client')
        api_client.authorization = authorization
        api_client.auto_refresh_token = true
        @project = project
        @credential_file = credential_file
        @dispatcher = APIDispatcher.new(:project=>project,:api_client=>api_client)
      end

      def self.from_json(filename = nil)
        filename ||= File.expand_path(DEFAULT_FILE)
        begin
		credential_data = MultiJson.load(File.read(filename))
        rescue
          $stdout.print "Error reading CREDENTIAL_FILE, please run 'knife google setup'\n"
          exit 1
        end
        authorization = Signet::OAuth2::Client.new(credential_data)
        self.new(authorization, credential_data['project'], filename)
      end

      def self.setup
        $stdout.print "Enter project ID (not name or number): "
        project = $stdin.gets.chomp
        $stdout.print "Enter client id: "
        client_id = $stdin.gets.chomp
        $stdout.print "Enter client secret: "
        client_secret = $stdin.gets.chomp
        authorization_uri = "https://accounts.google.com/o/oauth2/auth"
        token_credential_uri ="https://accounts.google.com/o/oauth2/token"
        scope  = ["https://www.googleapis.com/auth/compute",
          "https://www.googleapis.com/auth/compute.readonly",
          "https://www.googleapis.com/auth/devstorage.full_control",
          "https://www.googleapis.com/auth/devstorage.read_only",
          "https://www.googleapis.com/auth/devstorage.read_write",
          "https://www.googleapis.com/auth/devstorage.write_only",
          "https://www.googleapis.com/auth/userinfo.email"]
        redirect_uri = 'urn:ietf:wg:oauth:2.0:oob'

        api_client = Google::APIClient.new(:application_name=>'google-compute-ruby-client')

        api_client.authorization.scope = scope
        api_client.authorization.client_id = client_id
        api_client.authorization.client_secret = client_secret
        api_client.authorization.redirect_uri = redirect_uri
        $stdout.puts "Copy and paste the following url in your brower and allow access. Enter the resulting authorization code below.\n\n"
        $stdout.puts api_client.authorization.authorization_uri
        $stdout.print "\n\nAuthorization code: "
        authorization_code = $stdin.gets.chomp
        api_client.authorization.code = authorization_code
        
        begin
          api_client.authorization.fetch_access_token!
        rescue Faraday::Error::ConnectionFailed => e
          raise ConnectionFail,
            "The SSL certificates validation may not configured for this system. Please refer README to configured SSL certificates validation"\
              if e.message.include? "SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed"
        else
          access_token = api_client.authorization.access_token
          refresh_token = api_client.authorization.refresh_token
          id_token = api_client.authorization.id_token
          expires_in = api_client.authorization.expires_in
          issued_at = api_client.authorization.issued_at.to_s
          if !@credential_file
              filepath = File.expand_path(DEFAULT_FILE)
          else
              filepath = File.expand_path(@credential_file)
          end
          File.open(filepath,'w+') do |f|
            f.write(MultiJson.dump({"authorization_uri" => authorization_uri,
              "token_credential_uri"=>"https://accounts.google.com/o/oauth2/token",
              "scope"=>scope,"redirect_uri"=>redirect_uri, "client_id"=>client_id,
              "client_secret"=>client_secret, "access_token"=>access_token,
              "expires_in"=>expires_in,"refresh_token"=> refresh_token, "id_token"=>id_token,
              "issued_at"=>issued_at,"project"=>project }, :pretty=>true))
          end
        end
      end

      def projects
        ResourceCollection.new(:resource_class => Google::Compute::Project, :dispatcher => @dispatcher)
      end

      def disks
        CreatableResourceCollection.new(:resource_class => Google::Compute::Disk,  :dispatcher=>@dispatcher)
      end

      def firewalls
        CreatableResourceCollection.new(:resource_class => Google::Compute::Firewall, :dispatcher => @dispatcher)
      end

      def images
        CreatableResourceCollection.new(:resource_class => Google::Compute::Image, :dispatcher => @dispatcher)
      end

      def instances
        CreatableResourceCollection.new(:resource_class => Google::Compute::Server, :dispatcher=>@dispatcher)
      end

      def kernels
        ListableResourceCollection.new(:resource_class => Google::Compute::Kernel,:dispatcher=>@dispatcher)
      end

      def machine_types
        ListableResourceCollection.new(:resource_class => Google::Compute::MachineType,:dispatcher=>@dispatcher)
      end

      def networks
        CreatableResourceCollection.new(:resource_class => Google::Compute::Network, :dispatcher=>@dispatcher)
      end

      def globalOperations
        DeletableResourceCollection.new(:resource_class => Google::Compute::GlobalOperation, :dispatcher=>@dispatcher)
      end

      def regionOperations
        DeletableResourceCollection.new(:resource_class => Google::Compute::RegionOperation, :dispatcher=>@dispatcher)
      end

      def zoneOperations
        DeletableResourceCollection.new(:resource_class => Google::Compute::ZoneOperation, :dispatcher=>@dispatcher)
      end

      def regions
        ListableResourceCollection.new(:resource_class => Google::Compute::Region, :dispatcher=>@dispatcher)
      end

      def zones
        ListableResourceCollection.new(:resource_class => Google::Compute::Zone, :dispatcher=>@dispatcher)
      end

      def snapshots
        CreatableResourceCollection.new(:resource_class => Google::Compute::Snapshot, :dispatcher=>@dispatcher)
      end

      class APIDispatcher
        attr_reader :project, :api_client

        def initialize(opts)
          @project= opts[:project]
          @api_client = opts[:api_client]
        end

        def compute
          @compute ||= @api_client.discovered_api('compute','v1beta16')
        end
        
        def dispatch(opts)
          begin  
            unless opts[:parameters].has_key?(:project)
              opts[:parameters].merge!( :project => @project )
            end
            result = @api_client.execute(:api_method=>opts[:api_method],
                                    :parameters=>opts[:parameters],
                                    :body_object => opts[:body_object]
                                    )
            unless result.success?
              response = MultiJson.load(result.response.body)
              error_code = response["error"]["code"] 
              if error_code == 404
                raise ResourceNotFound, result.response.body 
              elsif error_code == 400
                raise BadRequest, result.response.body 
              else 
                raise BadRequest, result.response.body 
              end
            end  
            return MultiJson.load(result.response.body) unless result.response.body.nil?
          rescue ArgumentError => e
            raise ParameterValidation, e.message
          end  
        end
      end
    end
  end
end

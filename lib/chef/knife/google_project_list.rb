# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'chef/knife/google_base'
require 'time'

class Chef
  class Knife
    class GoogleProjectList < Knife

      include Knife::GoogleBase

      banner "knife google project list (options)"

      option :limits,
        :short => "-L",
        :long => "--with-limits",
        :description => "Additionally print the quota limit for each metric",
        :required => false,
        :boolean => true,
        :default => false 

      def run
        $stdout.sync = true

        project_list = [
          ui.color("name", :bold),
          ui.color('snapshots', :bold),
          ui.color('networks', :bold),
          ui.color('firewalls', :bold),
          ui.color('images', :bold),
          ui.color('routes', :bold),
          ui.color('forwarding-rules', :bold),
          ui.color('target-pools', :bold),
          ui.color('health-checks', :bold)].flatten.compact

        output_column_count = project_list.length

        project = client.projects.project

        project_list << project

        snapshots_usage = "0"
        snapshots_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "SNAPSHOTS"
            snapshots_usage = "#{quota["usage"].to_i}"
            snapshots_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          snapshots_quota = "#{snapshots_usage}/#{snapshots_limit}"
        else
          snapshots_quota = "#{snapshots_usage}"
        end
        project_list << snapshots_quota

        networks_usage = "0"
        networks_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "NETWORKS"
            networks_usage = "#{quota["usage"].to_i}"
            networks_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          networks_quota = "#{networks_usage}/#{networks_limit}" 
        else
          networks_quota = "#{networks_usage}"
        end
        project_list << networks_quota

        firewalls_usage = "0"
        firewalls_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "FIREWALLS"
           firewalls_usage = "#{quota["usage"].to_i}"
           firewalls_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          firewalls_quota = "#{firewalls_usage}/#{firewalls_limit}"
        else
          firewalls_quota = "#{firewalls_usage}"
        end
        project_list << firewalls_quota

        images_usage = "0"
        images_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "IMAGES"
            images_usage = "#{quota["usage"].to_i}"
            images_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          images_quota = "#{images_usage}/#{images_limit}"
        else
          images_quota = "#{images_usage}"
        end
        project_list << images_quota

        routes_usage = "0"
        routes_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "ROUTES"
            routes_usage = "#{quota["usage"].to_i}"
            routes_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          routes_quota = "#{routes_usage}/#{routes_limit}"
        else
          routes_quota = "#{routes_usage}"
        end
        project_list << routes_quota

        forwarding_usage = "0"
        forwarding_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "FORWARDING_RULES"
            forwarding_usage = "#{quota["usage"].to_i}"
            forwarding_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          forwarding_quota = "#{forwarding_usage}/#{forwarding_limit}"
        else
          forwarding_quota = "#{forwarding_usage}"
        end
        project_list << forwarding_quota

        target_usage = "0"
        target_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "TARGET_POOLS"
            target_usage = "#{quota["usage"].to_i}"
            target_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          target_quota = "#{target_usage}/#{target_limit}"
        else
          target_quota = "#{target_usage}"
        end
        project_list << target_quota

        health_usage = "0"
        health_limit = "0"
        client.projects.get(project).quotas.each do |quota|
          if quota["metric"] == "HEALTH_CHECKS"
            health_usage = "#{quota["usage"].to_i}"
            health_limit = "#{quota["limit"].to_i}"
          end
        end
        if config[:limits] == true
          health_quota = "#{health_usage}/#{health_limit}"
        else
          health_quota = "#{health_usage}"
        end
        project_list << health_quota

        ui.info(ui.list(project_list, :uneven_columns_across, output_column_count))
      end
    end
  end
end

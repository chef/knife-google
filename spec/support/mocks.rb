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

module Mocks
  SPEC_DATA_FOLDER = File.expand_path('../../data', __FILE__)

  def mock_data(klass)
    return File.read(mock_data_file(klass))
  end

  def mock_list_data(klass)
    return '{"items":[' + File.read(mock_data_file(klass)) + ']}'
  end

  def mock_data_file(klass)
    class_name = klass.name.split('::').last.underscore
    if class_name == "instance"
      json_file = File.expand_path(File.join(SPEC_DATA_FOLDER,  'server.json'))
    else
      json_file = File.expand_path(File.join(SPEC_DATA_FOLDER,  class_name + '.json'))
    end
  end

  def instance_from_mock_data(klass)
    klass.new(mock_hash(klass))
  end

  def mock_hash(klass)
    MultiJson.load(mock_data(klass))
  end

  def mock_compute
    @compute ||=
      begin
        data_file = File.join(SPEC_DATA_FOLDER, 'compute-v1.json')
        u = Addressable::URI.parse('URI:https://www.googleapis.com/discovery/v1/apis/compute/v1/rest')
        compute = Google::APIClient::API.new(u, MultiJson.load(File.read(data_file)))
      end
  end

  def mock_response(klass=nil, list = false)
    body = if klass.nil?
             nil
           elsif list
             mock_list_data(klass)
           else
             mock_data(klass)
           end
    double(klass, :success? => true, :response => double('some', :body => body))
  end
end

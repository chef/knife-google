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

shared_examples Google::Compute::Resource do

  let (:resource) do
    instance_from_mock_data(described_class)
  end

  it "should be of compute# kind" do
    resource.kind.should match('compute#')
  end

  it "should be a subclass of Google::Compute::Resource" do
    resource.should be_a_kind_of(Google::Compute::Resource)
  end

  it "#id should have a valid id" do
    resource.id.should be_a_kind_of(Integer)
  end

  it "#creation_timestamp should have a  valid creation timestamp" do
    unless resource.creation_timestamp.nil?
      resource.creation_timestamp.should be_a_kind_of(Time)
    end
  end

  it "#type should have same type is class" do
    # TODO(erjohnso): {global,zone}operations are not resources
    unless ["globaloperation", "zoneoperation"].include? resource.class.class_name
      resource.type.downcase.should eq(resource.class.class_name)
    else
      resource.type.downcase.should eq("operation")
    end
  end

  it "should have a valid description" do
    # TODO(erjohnso): {global,zone}operations are not resources
    # mock-{zone,global}-operation
    unless resource.name.split('-').last == "operation"
      resource.description.should_not be_nil
    end
  end

  it "#project should have a valid project name" do
    resource.project.should_not be_nil
  end

  it "#self_link should have a valid https self link" do
    URI.parse(resource.self_link).should be_a_kind_of(URI::HTTPS)
  end

  it "#to_s should return its name when converted to string" do
    resource.to_s.should eq(resource.name)
  end
end

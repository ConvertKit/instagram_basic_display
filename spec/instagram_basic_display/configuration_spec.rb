# frozen_string_literal: true

# Copyright 2020 ConvertKit, LLC
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

RSpec.describe InstagramBasicDisplay::Configuration do
  it 'pulls variables from ENV' do
    expect(subject.client_id).to eq 'mock_client_id'
    expect(subject.client_secret).to eq 'mock_secret'
    expect(subject.redirect_uri).to eq 'mock_redirect_uri'
  end

  context 'when ENV variables are not present' do
    it 'raises an error if ENV variables are not present' do
      populated_env = ENV
      ENV = {}.freeze
      expect { subject }.to raise_error KeyError
      ENV = populated_env
    end
  end

  it 'allows variables to be overwritten' do
    subject.client_id = 'different_client_id'
    expect(subject.client_id).to eq 'different_client_id'
  end
end

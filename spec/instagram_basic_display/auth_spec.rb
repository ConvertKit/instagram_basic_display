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

require 'vcr'

RSpec.describe InstagramBasicDisplay::Auth do
  let(:config) { InstagramBasicDisplay::Configuration.new }

  subject { InstagramBasicDisplay::Auth.new(config) }

  describe '#short_lived_token' do
    it 'exchanges an access code for a short lived token' do
      VCR.use_cassette('short_lived_token') do
        response = subject.short_lived_token(access_code: 'asdf')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.payload.access_token).to eq 'mock_access_token'
        expect(response.payload.user_id).to eq 1234567
        expect(response.success?).to eq true
      end
    end

    it 'returns an error response when the request fails' do
      VCR.use_cassette('short_lived_token_failed') do
        response = subject.short_lived_token(access_code: 'already_used_access_code')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.success?).to eq false
        expect(response.error.type).to eq 'OAuthException'
        expect(response.error.message).to eq 'Invalid authorization code'
        expect(response.error.code).to eq 400
      end
    end
  end

  describe '#long_lived_token' do
    it 'exchanges a short lived token for a long lived token' do
      VCR.use_cassette('long_lived_token') do
        response = subject.long_lived_token(short_lived_token: 'mock_short_lived_token')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.payload.access_token).to eq 'mock_long_lived_token'
        expect(response.payload.expires_in).not_to be_nil
        expect(response.payload.token_type).to eq 'bearer'
        expect(response.success?).to eq true
      end
    end

    it 'returns an error response when the request fails' do
      VCR.use_cassette('long_lived_token_failed') do
        response = subject.long_lived_token(short_lived_token: 'mock_short_lived_token')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.error.code).to eq 190
        expect(response.error.message).to eq 'Invalid OAuth access token.'
        expect(response.success?).to eq false
      end
    end
  end

  describe '#refresh_long_lived_token' do
    it 'returns a refreshed long lived token' do
      VCR.use_cassette('refresh_long_lived_token') do
        response = subject.refresh_long_lived_token(token: 'mock_long_lived_token')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.payload.access_token).to eq 'mock_long_lived_token'
        expect(response.payload.token_type).to eq 'bearer'
        expect(response.payload.expires_in).not_to be_nil
        expect(response.success?).to eq true
      end
    end

    it 'returns an error when the request fails' do
      VCR.use_cassette('refresh_long_lived_token_failed') do
        response = subject.refresh_long_lived_token(token: 'mock_short_lived_token')

        expect(response).to be_a InstagramBasicDisplay::Response
        expect(response.error.code).to eq 190
        expect(response.error.message).to eq 'Invalid OAuth access token.'
        expect(response.success?).to eq false
      end
    end
  end
end

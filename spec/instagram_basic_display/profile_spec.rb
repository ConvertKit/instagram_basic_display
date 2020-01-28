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

RSpec.describe InstagramBasicDisplay::Profile do
  let(:config) { InstagramBasicDisplay::Configuration.new(auth_token: 'mock_token') }

  subject { InstagramBasicDisplay::Profile.new(config) }

  it 'auth_token can be set on a call-by-call basis' do
    config = InstagramBasicDisplay::Configuration.new
    subject = InstagramBasicDisplay::Profile.new(config)
    expect { subject.profile(auth_token: 'different_token') }.not_to raise_error(InstagramBasicDisplay::NoAuthToken)
  end

  it 'throws an error if no auth token is provided' do
    config = InstagramBasicDisplay::Configuration.new
    subject = InstagramBasicDisplay::Profile.new(config)
    expect { subject.profile }.to raise_error(InstagramBasicDisplay::NoAuthToken)
  end

  describe '#profile' do
    it 'returns an instagram user\'s profile information' do
      VCR.use_cassette('profile') do
        response = subject.profile
        expect(response.success?).to eq true
        expect(response.payload.id).to eq 'mock_instagram_id'
        expect(response.payload.username).to eq 'mock_instagram_username'
        expect(response.error).to eq nil
      end
    end

    it 'returns an error if the request is rejected' do
      VCR.use_cassette('profile_failed') do
        response = subject.profile
        expect(response.success?).to eq false
        expect(response.error.message).to eq 'Invalid OAuth access token.'
        expect(response.error.code).to eq 190
        expect(response.error.type).to eq 'OAuthException'
      end
    end
  end

  describe '#media_feed' do
    it 'returns a list of the user\'s media' do
      VCR.use_cassette('media_feed') do
        response = subject.media_feed
        expect(response.success?).to eq true
        expect(response.payload.data).to be_a Array
        expect(response.payload.data.length > 1).to eq true
        expect(response.error).to eq nil
      end
    end

    it 'respects the given limit' do
      VCR.use_cassette('media_feed_with_limit') do
        response = subject.media_feed(limit: 2)
        expect(response.success?).to eq true
        expect(response.payload.data).to be_a Array
        expect(response.payload.data.length == 2).to eq true
        expect(response.error).to eq nil
      end
    end

    it 'returns an error if the request is rejected' do
      VCR.use_cassette('media_feed_failed') do
        response = subject.media_feed
        expect(response.success?).to eq false
        expect(response.error.message).to eq 'Invalid OAuth access token.'
        expect(response.error.type).to eq 'OAuthException'
        expect(response.error.code).to eq 190
      end
    end
  end

  describe '#media_feed_from_link' do
    it "returns a list of the user\'s media from the given link" do
      VCR.use_cassette('media_feed') do
        response = subject.media_feed

        VCR.use_cassette('media_feed_from_link') do
          next_response = subject.media_feed_from_link(page_link: response.next_page_link)

          expect(next_response.success?).to eq true
          expect(next_response.payload.data).to be_a Array
          expect(next_response.payload.data.length > 1).to eq true
          expect(next_response.error).to eq nil
        end
      end
    end
  end

  describe '#media_node' do
    it 'returns information for the given media' do
      VCR.use_cassette('media_node') do
        response = subject.media_node(media_id: '18046145275219342')
        expect(response.success?).to eq true
        expect(response.payload.media_url).not_to be_nil
        expect(response.payload.id).to eq '18046145275219342'
        expect(response.error).to eq nil
      end
    end

    it 'returns an error if the request is rejected' do
      VCR.use_cassette('media_node_failed') do
        response = subject.media_node(media_id: '18046145275219342')
        expect(response.success?).to eq false
        expect(response.error.message).to eq 'Invalid OAuth access token.'
        expect(response.error.type).to eq 'OAuthException'
        expect(response.error.code).to eq 190
      end
    end
  end
end

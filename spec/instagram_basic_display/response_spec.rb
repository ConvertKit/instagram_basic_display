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

RSpec.describe InstagramBasicDisplay::Response do
  let(:successful_response) { Net::HTTPSuccess.new(1.0, '200', 'OK') }

  describe '#success?' do
    it 'returns true if message is `OK`' do
      expect(successful_response).to receive(:body).and_return({}.to_json)
      response = InstagramBasicDisplay::Response.new(successful_response)

      expect(response.success?).to be_truthy
    end
  end

  context 'navigation' do
    let(:json) do
      {
        paging: {
          next: 'https://example.com/next',
          previous: 'https://example.com/previous'
        }
      }.to_json
    end

    describe '#next_page?' do
      it 'returns true if paging has a value for `next`' do
        expect(successful_response).to receive(:body).and_return(json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.next_page?).to eq(true)
      end

      it 'returns false if paging doesn\'t have a value for `next`' do
        expect(successful_response).to receive(:body).and_return({}.to_json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.next_page?).to eq(false)
      end
    end

    describe '#next_page_link' do
      it 'returns the value of paging[`next`] if present' do
        expect(successful_response).to receive(:body).and_return(json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.next_page_link).to eq('https://example.com/next')
      end
    end

    describe '#previous_page?' do
      it 'returns true if paging has a value for `previous`' do
        expect(successful_response).to receive(:body).and_return(json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.previous_page?).to eq(true)
      end

      it 'returns false if paging doesn\'t have a value for `previous`' do
        expect(successful_response).to receive(:body).and_return({}.to_json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.previous_page?).to eq(false)
      end
    end

    describe '#previous_page_link' do
      it 'returns the value of paging[`next`] if present' do
        expect(successful_response).to receive(:body).and_return(json)
        response = InstagramBasicDisplay::Response.new(successful_response)

        expect(response.previous_page_link).to eq('https://example.com/previous')
      end
    end
  end
end

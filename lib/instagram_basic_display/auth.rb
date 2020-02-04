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

require 'net/http'
require 'instagram_basic_display/configuration'
require 'instagram_basic_display/response'

module InstagramBasicDisplay
  class Auth
    def initialize(configuration)
      @configuration = configuration
    end

    def short_lived_token(access_code:)
      response = Net::HTTP.post_form(
        URI('https://api.instagram.com/oauth/access_token'),
        client_id: configuration.client_id,
        client_secret: configuration.client_secret,
        grant_type: 'authorization_code',
        redirect_uri: configuration.redirect_uri,
        code: access_code
      )

      InstagramBasicDisplay::Response.new(response)
    end

    def long_lived_token(short_lived_token: nil, access_code: nil)
      short_lived_token ||= short_lived_token(access_code: access_code).payload.access_token

      uri = URI('https://graph.instagram.com/access_token')
      params = {
        client_secret: configuration.client_secret,
        grant_type: 'ig_exchange_token',
        access_token: short_lived_token
      }
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)
      InstagramBasicDisplay::Response.new(response)
    end

    def refresh_long_lived_token(token:)
      uri = URI('https://graph.instagram.com/refresh_access_token')
      params = {
        grant_type: 'ig_refresh_token',
        access_token: token
      }
      uri.query = URI.encode_www_form(params)

      response = Net::HTTP.get_response(uri)
      InstagramBasicDisplay::Response.new(response)
    end

    private

    attr_reader :configuration
  end
end

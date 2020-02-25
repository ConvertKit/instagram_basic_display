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
require 'instagram_basic_display/errors'

module InstagramBasicDisplay
  class Profile
    def initialize(configuration)
      @configuration = configuration
    end

    def profile(user_id: nil, fields: %i[id username], **params)
      check_for_auth_token!(params)

      uri = URI(base_profile_uri(user_id: user_id))
      params = {
        fields: fields.map(&:to_s).join(','),
        access_token: configuration.auth_token,
        **params
      }

      make_request(uri, params)
    end

    # document that you can add a limit here
    def media_feed(user_id: nil, fields: %i[id media_url], paginated_url: nil, **params)
      check_for_auth_token!(params)

      uri = if paginated_url
              URI(paginated_url)
            else
              URI(base_profile_uri(user_id: user_id) + '/media')
            end

      params = {
        fields: fields.map(&:to_s).join(','),
        access_token: configuration.auth_token,
        **params
      }

      make_request(uri, params)
    end


    def media_node(media_id:, fields: %i[id media_url], **params)
      check_for_auth_token!(params)

      uri = URI("https://graph.instagram.com/#{media_id}")
      params = {
        fields: fields.map(&:to_s).join(','),
        access_token: configuration.auth_token,
        **params
      }

      make_request(uri, params)
    end

    private

    def make_request(uri, params = {})
      uri.query = consolidate_query_string(uri, params)

      response = Net::HTTP.get_response(uri)
      InstagramBasicDisplay::Response.new(response)
    end

    def check_for_auth_token!(params)
      token = params[:auth_token]
      configuration.auth_token = token if token

      raise InstagramBasicDisplay::NoAuthToken, 'please provide an auth token' unless configuration.auth_token
    end

    def base_profile_uri(user_id: nil)
      "https://graph.instagram.com/#{user_id || 'me'}"
    end

    def consolidate_query_string(uri, params = {})
      parsed_query_string = uri.query.to_s
                               .split('&')
                               .map { |pair| pair.split('=') }
                               .to_h

      params = params.transform_keys(&:to_s)
      params = parsed_query_string.merge(params)

      URI.encode_www_form(params)
    end

    attr_reader :configuration
  end
end

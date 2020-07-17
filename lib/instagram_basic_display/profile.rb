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
  # Module for interacting with an Instagram user's profile. You can retrieve profile information
  #  and media.
  class Profile
    # Constructor
    #
    # @param configuration [InstagramBasicDisplay::Configuration] the configuration
    #   information to use when making requests to Instagram.
    #
    # @return void
    def initialize(configuration)
      @configuration = configuration
    end

    # Method for interacting with an Instagram user's profile. Can be used to retrieve
    #   information such as their id and username.
    #
    # @param user_id [String] the id of the user whose information you are retrieving.
    #   If no user_id is passed, the query will be made agains the user associated with the
    #   current auth token.
    #
    # @param fields [Array<Symbol>] array of fields to retrieve. Defaults to id and username.
    #   The full list of fields can be found in the Instagram documentation:
    #   https://developers.facebook.com/docs/instagram-basic-display-api/reference/user#fields
    #
    # @param params [Hash] any additional request parameters that should be passed to the API.
    #
    # @return [InstagramBasicDisplay::Response] a response object containing the response from
    #   the Instagram API.
    #
    # @raise [InstagramBasicDisplay::NoAuthToken] raises when no auth token is provided in the
    #  client configuration
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

    # Method for retrieving a user's media feed.
    #
    # @param user_id [String] the id of the user whose information you are retrieving.
    #   If no user_id is passed, the query will be made agains the user associated with the
    #   current auth token.
    #
    # @param fields [Array<Symbol>] array of fields to retrieve. Defaults to id and media_url.
    #   The full list of fields can be found in the Instagram documentation:
    #   https://developers.facebook.com/docs/instagram-basic-display-api/reference/media/
    #
    # @param paginated_url [String] a url to retrieve the next or previous set of results
    #   from the API. This url is provided by the response from Instagram.
    #
    # @param params [Hash] any additional request parameters that should be passed to the API
    #
    # @raise [InstagramBasicDisplay::NoAuthToken] raises when no auth token is provided in the
    #  client configuration
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

    # Method for retrieving information for a particular media node (i.e. one image or video).
    #
    # @param media_id [String] the id of the media you are querying for.
    #
    # @param fields [Array<Symbol>] array of fields to retrieve. Defaults to id and media_url.
    #   The full list of fields can be found in the Instagram documentation:
    #   https://developers.facebook.com/docs/instagram-basic-display-api/reference/media/
    #
    # @param params [Hash] any additional request parameters that should be passed to the API
    #
    # @raise [InstagramBasicDisplay::NoAuthToken] raises when no auth token is provided in the
    #  client configuration
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

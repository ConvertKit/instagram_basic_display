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
  # A module to handle authentication requests to the Instagram API. Allows you to retrieve
  # short- and long-lived tokens, and refresh long-lived tokens.
  #
  # Does not handle retrieving access codes. These must be retrieved by implementing Instagram's
  #  authentication window.
  #  https://developers.facebook.com/docs/instagram-basic-display-api/overview#authentication-window
  class Auth
    # Constructor
    #
    # @param configuration [InstagramBasicDisplay::Configuration] configuration information
    #   that should be used to make requests against the Instagram API.
    #
    # @return void
    def initialize(configuration)
      @configuration = configuration
    end

    # Exchanges an access code for a _short-lived_ access token. A short-lived token is valid
    # for one hour, but can be exchanged for a long-lived token. Refer to Instagram's documentation.
    # https://developers.facebook.com/docs/instagram-basic-display-api/overview#short-lived-access-tokens
    #
    # @param access_code [String] A code retrieved by implementing Instagram's authentication window
    #   flow: https://developers.facebook.com/docs/instagram-basic-display-api/overview#authentication-window
    #
    # @return [InstagramBasicDisplay::Response] a response object containing either the token or an error
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

    # Exchanges _either_ an access code OR a short-lived token for a long-lived token.
    #  If an access code is passed, it will first be exchanged for a short-lived token.
    #  Once that is achieved, the short-lived token will be exchanged for a long-lived token.
    #  Refer to Instagram's documentation for more information on tokens:
    #  https://developers.facebook.com/docs/instagram-basic-display-api/overview
    #
    # @return [InstagramBasicDisplay::Response] a response object containing either the token or an error
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

    # Refreshes a long-lived token for a new period of validity.
    #
    # @return [InstagramBasicDisplay::Response] a response object containing either the token or an error
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

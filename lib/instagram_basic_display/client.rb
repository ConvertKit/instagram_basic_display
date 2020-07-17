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

require 'forwardable'
require 'instagram_basic_display/auth'
require 'instagram_basic_display/profile'

module InstagramBasicDisplay
  # Exposes all the functionality of the gem, so that you can interact with the Instagram API.
  # Methods are defined in separate modules, but delegated here for simplicity when interacting
  # with the gem.
  class Client
    extend Forwardable

    def_delegators :@auth, :short_lived_token, :long_lived_token, :refresh_long_lived_token
    def_delegators :@profile, :profile, :media_feed, :media_node, :media_feed_from_link

    # Constructor method
    #
    # @param auth_token [String] optionally pass an auth token that will be used to
    # make requests. If you do not have a token, you can retrieve one by using the
    # authentication utilities provided.
    #
    # @return void
    def initialize(auth_token: nil)
      @auth_token = auth_token

      @auth = Auth.new(configuration)
      @profile = Profile.new(configuration)
    end

    # Configuration that will be used to make requests against the Instagram API:
    # redirect_uri, client secret, and client ID. These are automatically picked up from
    # environment variables. Optionally, you can pass an auth token which will be used
    # to make requests.
    #
    # @return [InstagramBasicDisplay::Configuration]
    def configuration
      @configuration ||= InstagramBasicDisplay::Configuration.new(auth_token: @auth_token)
    end

    # Sets the gem's configuration
    #
    # @return void
    def configure
      yield(configuration) if block_given?
      nil
    end
  end
end

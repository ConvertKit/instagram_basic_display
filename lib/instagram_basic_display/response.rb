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

module InstagramBasicDisplay
  class Response
    attr_reader :status, :body, :response, :paging

    def initialize(response)
      @response = response
      @body = JSON.parse(response.body)
      @status = response.code
      @paging = @body['paging']
    end

    def next_page_link
      paging['next']
    end

    def previous_page_link
      paging['previous']
    end

    def success?
      response.message == 'OK'
    end

    def payload
      deserialize_json(body)
    end

    def error
      return unless body['error'] || body['error_message']

      error_response = normalize_error(body)
      deserialize_json(error_response)
    end

    private

    def normalize_error(error)
      if error['error_message']
        error.transform_keys { |key| key.gsub('error_', '') }
      else
        error['error']
      end
    end

    def deserialize_json(json)
      keys = json.keys.map(&:to_sym)
      Struct.new(*keys).new(*json.values)
    end
  end
end


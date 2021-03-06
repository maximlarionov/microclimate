require 'json'
# Represents a source code repository object on CodeClimate.
module Microclimate
  class Repository < Base
    attr_accessor :repo_id, :client

    extend Forwardable

    # @param [Hash] options An option hash of:
    #   +repo_id+: The SHA identifier of the repository on Code Climate.
    def initialize(client, options)
      @client = client
      @repo_id = options[:repo_id]
    end

    delegate :api_token => :client,
      :id => :status,
      :gpa => :last_snapshot

    # Force Code Climate to refresh this repository (at the master branch)
    def refresh!
      output = connection.post resource_refresh_url, :api_token => api_token
      output.success?
    end

    def ready?
      !last_snapshot.nil?
    end

    def status
      output = connection.get resource_url, :api_token => api_token
      json = output.body
      Response.new JSON.parse(json)
    end

    def branch_for(branch_name)
      Branch.new(client, self, branch_name)
    end

    def www_url
      "https://codeclimate.com/repos/#{repo_id}"
    end

    def last_snapshot
      snapshot = status.last_snapshot
      return nil if snapshot.nil?
      Snapshot.new(snapshot)
    end

    def previous_snapshot
      snapshot = status.previous_snapshot
      return nil if snapshot.nil?

      Snapshot.new(snapshot)
    end

    protected

    def resource_refresh_url
      "#{resource_url}/refresh"
    end

    def resource_url
      "/api/repos/#{repo_id}"
    end
  end
end


# frozen_string_literal: true

# Attribute mapping for alerts via generic alerting integration.
module Gitlab
  module AlertManagement
    module Payload
      class Generic < Base
        DEFAULT_TITLE = 'New: Incident'
        DEFAULT_SEVERITY = 'critical'

        attribute :hosts, paths: 'hosts'
        attribute :monitoring_tool, paths: 'monitoring_tool'
        attribute :runbook, paths: 'runbook'
        attribute :service, paths: 'service'
        attribute :severity, paths: 'severity', fallback: -> { DEFAULT_SEVERITY }
        attribute :starts_at, paths: 'start_time', type: :time, fallback: -> { Time.current.utc }
        attribute :title, paths: 'title', fallback: -> { DEFAULT_TITLE }

        attribute :plain_gitlab_fingerprint, paths: 'fingerprint'
        private :plain_gitlab_fingerprint
      end
    end
  end
end

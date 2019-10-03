# frozen_string_literal: true

module Tap
  class Charge < APIResource
    extend Tap::APIOperations::PostList
    extend Tap::APIOperations::Create
    include Tap::APIOperations::Save

    OBJECT_NAME = 'charge'.freeze

    IN_PROGRESS_STATUSES = ['INITIATED', 'IN_PROGRESS'].freeze
    FAILED_STATUSES = ['ABANDONED', 'CANCELLED', 'FAILED', 'DECLINED', 'RESTRICTED'].freeze
    ISSUE_STATUSES = ['VOID', 'TIMEDOUT', 'UNKNOWN'].freeze
    SUCCESS_STATUSES = ['CAPTURED'].freeze

    def in_progress?
      IN_PROGRESS_STATUSES.include?(status)
    end

    def failed?
      (FAILED_STATUSES + ISSUE_STATUSES).include?(status)
    end

    def success?
      SUCCESS_STATUSES.include?(status)
    end
  end
end

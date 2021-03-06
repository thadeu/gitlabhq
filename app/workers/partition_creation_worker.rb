# frozen_string_literal: true

class PartitionCreationWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :database
  idempotent!

  def perform
    Gitlab::Database::Partitioning::PartitionCreator.new.create_partitions
  end
end

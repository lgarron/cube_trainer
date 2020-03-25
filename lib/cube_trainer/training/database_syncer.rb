# frozen_string_literal: true

require 'cube_trainer/training/download_state'

module CubeTrainer
  module Training
    # Class that syncs a model with the global database.
    class DatabaseSyncer
      def initialize(model)
        @model = model
      end

      def logger
        @logger ||= Rails.logger
      end

      def hostname
        @hostname ||= @model.current_hostname
      end

      def upload!
        uploaded = fetch_uploaded
        puts "Uploading #{uploaded.length} records of type #{@model.name}."
        ActiveRecord::Base.connected_to(database: :global) do
          uploaded.each do |item|
            item.uploaded_at = Time.now
            item.dup.save!
          end
        end
        ActiveRecord::Base.connected_to(database: :primary) do
          uploaded.each { |item| item.save!(touch: false) }
        end
      end

      def download!
        download_state = fetch_download_state
        now = Time.now
        downloaded = fetch_downloaded
        puts "Inserting #{downloaded.length} downloaded records of type #{@model.name}."
        download_state.downloaded_at = now
        ActiveRecord::Base.connected_to(database: :primary) do
          downloaded.each(&:save!)
          download_state.save!
        end
      end

      def sync!
        upload!
        download!
      end

      private

      def fetch_uploaded
        ActiveRecord::Base.connected_to(database: :primary) do
          @model.where(
            'hostname = ? AND (uploaded_at IS NULL OR updated_at > uploaded_at)',
            hostname
          ).to_a
        end
      end

      def fetch_downloaded
        ActiveRecord::Base.connected_to(database: :global) do
          @model.where(
            'hostname != ? AND uploaded_at > ? AND uploaded_at <= ?',
            hostname, download_state.downloaded_at, now
          ).to_a
        end
      end

      def fetch_download_state
        ActiveRecord::Base.connected_to(database: :primary) do
          DownloadState.create_or_find_by!(model: @model.name)
        end
      end
    end
  end
end

module Hydra
  module Queue
    class Resque
      attr_reader :default_queue_name

      ENCAPSULATED_CLASS = "_encapsulated_class".freeze

      def initialize(default_queue_name)
        @default_queue_name = default_queue_name
      end

      def push(job)
        queue = job.respond_to?(:queue_name) ? job.queue_name : default_queue_name
        # this can raise a Redis::CannotConnectError
        ::Resque.enqueue_to queue, JsonJob, JsonJob.serialize(job)
      end

      class JsonJob
        def self.perform(job_data)
          deserialize(job_data).run
        end
        def self.serialize(job)
          job.as_json.merge(ENCAPSULATED_CLASS => job.class.name).to_json
        end

        def self.deserialize(job_data)
          data = JSON.parse(job_data)
          class_name = data.delete(ENCAPSULATED_CLASS)
          class_name.constantize.allocate.tap do |obj|
            data.each do |key, value|
              obj.instance_variable_set(:"@#{key}", value)
            end
          end
        end
      end
    end
  end
end

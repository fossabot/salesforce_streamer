module SalesforceStreamer
  class Server
    attr_writer :push_topics

    def initialize(push_topics: [])
      @push_topics = push_topics
    end

    def run
      Log.info 'Starting Server'
      catch_signals
      start_em
    end

    private

    def catch_signals
      %w[INT USR1 USR2 TERM TTIN TSTP].each do |sig|
        trap sig do
          puts "Caught signal #{sig}. Shutting down..."
          exit 0
        end
      end
    end

    def client
      Restforce.new.tap(&:authenticate!)
    end

    def start_em
      EM.run do
        @push_topics.map do |topic|
          client.subscribe topic.name, replay: topic.replay.to_i do |msg|
            Log.info "Message received from topic #{topic.name}"
            MessageReceiver.call topic.name, topic.handler_constant, msg
          end
        end
      end
    end
  end
end

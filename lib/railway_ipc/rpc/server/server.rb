# frozen_string_literal: true

require 'railway_ipc/rpc/server/server_response_handlers'
require 'railway_ipc/rpc/concerns/error_adapter_configurable'
require 'railway_ipc/rpc/concerns/message_observation_configurable'

module RailwayIpc
  class Server
    extend RailwayIpc::RPC::ErrorAdapterConfigurable
    extend RailwayIpc::RPC::MessageObservationConfigurable
    attr_reader :message, :responder

    def self.respond_to(message_type, with:)
      RailwayIpc::RPC::ServerResponseHandlers.instance.register(handler: with, message: message_type)
    end

    def initialize(_queue, _pool, opts={ automatic_recovery: true }, rabbit_adapter: RailwayIpc::Rabbitmq::Adapter)
      @rabbit_connection = rabbit_adapter.new(
        queue_name: self.class.queue_name,
        exchange_name: self.class.exchange_name,
        options: opts
      )
    end

    def run
      rabbit_connection
        .connect
        .create_exchange
        .create_queue(durable: true)
        .bind_queue_to_exchange
      subscribe_to_queue
    end

    def stop
      rabbit_connection.disconnect
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def work(payload)
      decoded_payload = RailwayIpc::Rabbitmq::Payload.decode(payload)
      case decoded_payload.type
      when *registered_handlers
        responder = get_responder(decoded_payload)
        @message = get_message_class(decoded_payload).decode(decoded_payload.message)
        responder.respond(message)
      else
        @message = LearnIpc::ErrorMessage.decode(decoded_payload.message)
        raise RailwayIpc::UnhandledMessageError.new("#{self.class} does not know how to handle #{decoded_payload.type}")
      end
    rescue StandardError => e
      RailwayIpc.logger.error(
        e.message,
        feature: 'railway_ipc_consumer',
        exchange: self.class.exchange_name,
        queue: self.class.queue_name,
        error: e.class,
        payload: payload
      )
      raise e
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def handle_request(payload)
      response = work(payload)
    rescue StandardError => e
      RailwayIpc.logger.error(
        'Error responding to message.',
        exception: e,
        feature: 'railway_ipc_consumer',
        exchange: self.class.exchange_name,
        queue: self.class.queue_name,
        protobuf: { type: message.class, data: message }
      )
      response = self.class.rpc_error_adapter_class.error_message(e, message)
    ensure
      if response
        rabbit_connection.reply(
          RailwayIpc::Rabbitmq::Payload.encode(response), message.reply_to
        )
      end
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    private

    attr_reader :rabbit_connection

    def get_message_class(decoded_payload)
      RailwayIpc::RPC::ServerResponseHandlers.instance.get(decoded_payload.type).message
    end

    def get_responder(decoded_payload)
      RailwayIpc::RPC::ServerResponseHandlers.instance.get(decoded_payload.type).handler.new
    end

    def registered_handlers
      RailwayIpc::RPC::ServerResponseHandlers.instance.registered
    end

    def subscribe_to_queue
      rabbit_connection.subscribe do |_delivery_info, _metadata, payload|
        handle_request(payload)
      end
    end
  end
end

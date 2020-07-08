# frozen_string_literal: true

module RailwayIpc
  class IncomingMessage
    attr_reader :type, :payload, :parsed_payload, :errors

    def initialize(payload)
      @parsed_payload = JSON.parse(payload)
      @type = parsed_payload['type']
      @payload = payload
      @errors = {}
    rescue JSON::ParserError => e
      raise RailwayIpc::IncomingMessage::ParserError, e
    end

    def uuid
      decoded.uuid
    end

    def user_uuid
      decoded.user_uuid
    end

    def correlation_id
      decoded.correlation_id
    end

    def valid?
      errors[:uuid] = 'uuid is required' unless uuid.present?
      unless correlation_id.present?
        errors[:correlation_id] = 'correlation_id is required'
      end
      errors.none?
    end

    def decoded
      @decoded ||=
        begin
          protobuf_msg = Base64.decode64(parsed_payload['encoded_message'])
          decoder = Kernel.const_get(type)
          decoder.decode(protobuf_msg)
        rescue Google::Protobuf::ParseError => e
          raise RailwayIpc::IncomingMessage::ParserError, e
        rescue NameError
          RailwayIpc::Messages::Unknown.decode(protobuf_msg)
        end
    end

    def stringify_errors
      errors.values.join(', ')
    end
  end
end

require_relative "./test_message_pb.rb"
require_relative "./test_handler.rb"
module RailwayIpc
  class TestConsumer < RailwayIpc::Consumer
    listen_to queue: "ironboard:test:commands", exchange: "test:commands"
    handle LearnIpc::Commands::TestMessage, with: RailwayIpc::TestHandler
  end
end

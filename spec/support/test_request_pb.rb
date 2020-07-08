# frozen_string_literal: true

# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: requests/batches.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message 'learn_ipc.requests.TestRequest' do
    optional :user_uuid, :string, 1
    optional :correlation_id, :string, 2
    optional :uuid, :string, 3
    optional :reply_to, :string, 4
    map :context, :string, :string, 5
  end
end

module LearnIpc
  module Requests
    TestRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup('learn_ipc.requests.TestRequest').msgclass
  end
end

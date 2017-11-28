# frozen_string_literal: true

module AwsCftTools
  ##
  # Provides common "closure" of paged results for the CFT client.
  #
  class AWSEnumerator < Enumerator
    #
    # @param client [Object] The client object used to retrieve the next set of responses.
    # @param method [Symbol] The method to call on the client object.
    # @param args [Hash] Any arguments that are the same across calls to the client object.
    # @yield [Object] The response from calling the +method+ on the +client+.
    #
    # @example Enumerating All Stacks
    #
    #   aws_client = Aws::CloudFormation::Client.new
    #   all_stacks = AWSEnumerator.new(aws_client, :describe_stacks, &:stacks).to_a
    #
    def initialize(client, method, args = {}, &block)
      @client = client
      @method = method
      @next_token = nil
      @args = args

      super() do |yielder|
        run_loop(yielder, &block)
      end
    end

    private

    def run_loop(yielder, &block)
      resp = poll_client
      loop do
        process_response(yielder, resp, &block)
        break unless @next_token
        resp = poll_client
      end
    end

    def process_response(yielder, resp)
      feed_results(yielder, yield(resp))
    end

    def poll_client
      resp = @client.public_send(@method, @args.merge(next_token: @next_token))
      @next_token = resp.next_token
      resp
    end

    def feed_results(yielder, results)
      results.each { |item| yielder << item }
    end
  end
end

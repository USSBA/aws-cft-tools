# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe AwsCftTools::ThreadedOutput do
  let(:stringio) { StringIO.new }
  let(:output) { described_class.new(stringio) }

  describe 'prefix' do
    let(:threaded_prefixes) do
      prefixes = []
      output # make sure output is created outside of the threads
      threads = (1..2).map do |t|
        Thread.new do
          described_class.prefix = "thread-#{t}"
          prefixes[t] = output.prefix
        end
      end
      threads.map(&:join)
      prefixes
    end

    it 'has different prefixes for different threads' do
      expect(threaded_prefixes).to eq [nil, 'thread-1: ', 'thread-2: ']
    end

    it 'writes with a prefix' do
      described_class.prefix = 'thread-prefix'
      output.puts('This is a line')
      expect(stringio.string).to eq "thread-prefix: This is a line\n"
    end
  end

  describe 'write' do
    before do
      described_class.prefix = 'thread-prefix'
    end

    it "doesn't output until there's a newline" do
      output.write('foo')
      expect(stringio.string).to eq ''
    end

    it "writes when there's a newline" do
      output.write("foo\nbar")
      expect(stringio.string).to eq "thread-prefix: foo\n"
    end
  end

  describe 'flush' do
    before do
      described_class.prefix = 'thread-prefix'
    end

    it "doesn't output if there's nothing in the buffer" do
      output.flush
      expect(stringio.string).to eq ''
    end

    it 'outputs whatever is left in the buffer' do
      output.write('foo')
      output.flush
      expect(stringio.string).to eq "thread-prefix: foo\n"
    end
  end
end

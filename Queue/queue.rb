#!/usr/bin/env ruby

require 'minitest'
require 'minitest/spec'

# Build a queue data structure in Ruby.

# - The queue should implement the enqueue and dequeue to control the queue
# - The queue should implement a peek method to see what's at the front of the qeueu
# - Write tests/specs to cover the functionality of the queue
# - Implement a small booking system that uses the queue

class Queue
  class Node
    attr_accessor :next, :data

    def initialize(data)
      self.data = data
      self.next = nil
    end
  end

  attr_accessor :front, :back, :size

  # Initialize an empty queue
  def initialize
    self.front = nil
    self.back = nil
    self.size = 0
  end

  # Inserts a new element into the back of the queue
  def enqueue(data)
    node = Node.new data

    if front
      back.next = node
    else
      self.front = node
    end

    self.back = node
    self.size += 1
  end

  # Removes the front element from the queue
  def dequeue
    return nil unless self.size.positive?

    data = self.front.data

    self.front = front.next
    self.back = nil if self.size == 1
    self.size -= 1

    return data
  end

  # Returns the front element in the queue without dequeing it
  def peek
    front
  end

  # Empties the queue
  def empty
    dequeue while peek
  end

  # Loops over the queue yield one node at a time
  def each
    return nil unless block_given?

    current = front
    while current
      yield current
      current = current.next
    end
  end
end

# Start of our test suite.
describe Queue do
  it 'returns 0 for a new queue' do
    queue = Queue.new

    _(queue.size).must_equal 0
  end
end

describe 'Queue#enqueue' do
  it 'add the first node to the front and back of the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')

    _(queue.size).must_equal 1
    _(queue.front.data).must_equal 'tiger@example.com'
    _(queue.back.data).must_equal 'tiger@example.com'
  end

  it 'adds subsequent nodes to the back of the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')

    _(queue.size).must_equal 2
    _(queue.front.data).must_equal 'tiger@example.com'
    _(queue.back.data).must_equal 'brooks@example.com'
  end
end

describe 'Queue#dequeue' do
  it 'removes a node from the front of the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')
    queue.enqueue('rory@example.com')

    queue.dequeue
    _(queue.size).must_equal 2
    _(queue.front.data).must_equal 'brooks@example.com'
    _(queue.back.data).must_equal 'rory@example.com'
  end

  it 'returns the node data' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')
    queue.enqueue('rory@example.com')

    node_data = queue.dequeue
    _(node_data).must_equal 'tiger@example.com'
  end
end

describe 'Queue#peek' do
  it 'returns the node at the front of the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')
    queue.enqueue('rory@example.com')

    _(queue.peek.data).must_equal 'tiger@example.com'
  end
end

describe 'Queue#empty' do
  it 'clears all nodes from the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')
    queue.enqueue('rory@example.com')

    queue.empty

    _(queue.size).must_equal 0
  end
end

describe 'Queue#each' do
  it 'iterates over the queue' do
    queue = Queue.new
    queue.enqueue('tiger@example.com')
    queue.enqueue('brooks@example.com')
    queue.enqueue('rory@example.com')

    nodes = []

    queue.each do |node|
      nodes << node.data
    end

    _(nodes).must_equal ['tiger@example.com', 'brooks@example.com', 'rory@example.com']
  end
end

# Start of the main script.
if Minitest.run
  puts "Tests passed! 😀 Proceeding to queue...\n\n\n"

  # Our booking system allows sends out a notification to each
  # account, allowing them to book their tee-time.
  # In a real world example this be done every five minutes.
  Account = Struct.new(:name, :email)

  tiger = Account.new('Tiger', 'tiger@example.com')
  brooks = Account.new('Brooks', 'brooks@example.com')
  rory = Account.new('Rory', 'rory@example.com')

  booking_queue = Queue.new
  booking_queue.enqueue(brooks)
  booking_queue.enqueue(rory)
  booking_queue.enqueue(tiger)

  puts "Let's send out booking notifications ..."
  while booking_queue.size.positive?
    account = booking_queue.dequeue
    puts "Sending booking notification to #{account.name} at #{account.email}"
    sleep(3)
  end
else
  puts 'Test failed! 😧 Queue aborted.'
end

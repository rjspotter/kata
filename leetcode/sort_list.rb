# https://leetcode.com/problems/sort-list/description/

# Definition for singly-linked list.
class ListNode
  attr_accessor :val, :next
  def initialize(val)
    @val = val
    @next = nil
  end
end

class QuickSort

  attr_reader :tracker
  def initialize
    @holder = ListNode.new(nil)
    @tracker = nil
    @steps = 0
  end

  def update_tracker(cell)
    unless cell.nil?
      @tracker ||= cell
      @tracker = cell if cell.val < @tracker.val
    end
  end

  def partition_list(head, limit = nil, holder = nil)
    # puts "#"*60
    # puts head.inspect
    # puts limit.inspect
    # puts holder.inspect
    # puts "-"*60
    puts @steps += 1
    binding.pry if @steps > 255

    unless head.nil? || head == limit || head.next == limit

      pivot      = head
      tail       = head.next
      holder   ||= @holder
      less_point = holder
      more_point = limit
      pivot.next = more_point

      update_tracker(pivot)

      until tail == limit
        update_tracker(tail)
        if tail.val >= pivot.val
          donext = tail.next
          tail.next = more_point
          more_point = tail
          pivot.next = more_point
          tail = donext
        elsif tail.val < pivot.val
          donext = tail.next
          tail.next = pivot
          less_point.next = tail
          less_point = tail
          tail = donext
        end
      end
      ret = holder.next
      @holder.next = nil

      partition_list(ret, pivot, holder) # left
      partition_list(pivot.next, nil, pivot) # right
    end

  end
end

# @param {ListNode} head
# @return {ListNode}
def sort_list(head)
  if head.nil? || head.next.nil?
    head
  else
    x = QuickSort.new
    x.partition_list(head)
    x.tracker
  end
end

# foo = [-1,5,3,4,0]
# foo = [4,2,1,3]
# foo = [1, 2, 3, 4, 5, 6, 7]
foo = [-84,142,41,-17,-71,170,186,183,-21,-76,76,10,29,81,112,-39,-6,-43,58,41,111,33,69,97,-38,82,-44,-7,99,135,42,150,149,-21,-30,164,153,92,180,-61,99,-81,147,109,34,98,14,178,105,5,43,46,40,-37,23,16,123,-53,34,192,-73,94,39,96,115,88,-31,-96,106,131,64,189,-91,-34,-56,-22,105,104,22,-31,-43,90,96,65,-85,184,85,90,118,152,-31,161,22,104,-85,160,120,-31,144,115]

bar = foo.reverse.inject(nil) do |m,x|
  ListNode.new(x).tap do |n|
    n.next = m
  end
end

puts "@"*88
puts (baz = sort_list(bar)).inspect

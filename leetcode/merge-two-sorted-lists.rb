# https://leetcode.com/problems/merge-two-sorted-lists/description/
# Definition for singly-linked list.
class ListNode
    attr_accessor :val, :next
    def initialize(val)
        @val = val
        @next = nil
    end
end

list_1_4 = ListNode.new 4
list_1_2 = ListNode.new 2
list_1_1 = ListNode.new 1

list_1_2.next = list_1_4
list_1_1.next = list_1_2

list_2_4 = ListNode.new 4
list_2_3 = ListNode.new 3
list_2_1 = ListNode.new 1

list_2_3.next = list_2_4
list_2_1.next = list_2_3



# @param {ListNode} l1
# @param {ListNode} l2
# @return {ListNode}
def merge_two_lists(l1, l2)
  head_1   = l1
  head_2   = l2
  head_new = nil
  pointer  = nil

  if head_1.nil? || head_2.nil?
    head_new = head_1 || head_2
    head_1, head_2 = nil, nil
  end

  until head_1.nil? && head_2.nil?
    puts "#"*88
    puts head_1.inspect
    puts head_2.inspect
    puts pointer.inspect
    puts "-"*88
    if pointer
      if head_1.nil?
        pointer.next = head_2
        head_2 = nil
      elsif head_2.nil?
        pointer.next = head_1
        head_1 = nil
      elsif head_1.val <= head_2.val
        pointer.next = head_1
        pointer      = head_1
        head_1       = head_1.next
      elsif head_1.val > head_2.val
        pointer.next = head_2
        pointer      = head_2
        head_2       = head_2.next
      else
        raise
      end
    else
      if head_1.val <= head_2.val
        head_new = head_1
        pointer  = head_1
        head_1   = head_1.next
      else
        head_new = head_2
        pointer  = head_2
        head_2   = head_2.next
      end
    end
  end
  head_new
end

merge_two_lists(list_1_1, list_2_1)

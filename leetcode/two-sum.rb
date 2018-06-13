# https://leetcode.com/problems/two-sum/description/

# @param {Integer[]} nums
# @param {Integer} target
# @return {Integer[]}
def two_sum(nums, target)
    TwoSum.new(nums, target).solve
end

class TwoSum

  attr_accessor :nums, :target, :solution
  def initialize(nums, target)
    @nums    = nums
    @target  = target
  end

  def working
    @working ||= begin
                   if nums.any? {|x| x < 0}
                     nums
                   else
                     nums.select {|x| x <= target}
                   end
                 end
  end

  def evens
    @evens ||= working.select(&:even?).sort
  end

  def odds
    @odds ||= working.select(&:odd?).sort
  end

  def solve
    if @target.even?
      solve_even
    else
      solve_odd
    end
    [nums.index(solution.first), nums.rindex(solution.last)].sort
  end

  # even numbers can only be the sum of two evens or two odds
  def solve_even
    while evens.length > 1 && !solution
      largest = evens.pop
      evens.each {|n| @solution = [n, largest] if n + largest == target}
    end
    while odds.length > 1 && !solution
      largest = odds.pop
      odds.each {|n| @solution = [n, largest] if n + largest == target}
    end
  end

  def solve_odd
    while evens.length > 0 && !solution
      largest = evens.pop
      odds.each {|n| @solution = [n, largest] if n + largest == target}
    end
  end
end

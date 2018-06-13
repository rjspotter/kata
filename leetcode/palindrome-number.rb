# https://leetcode.com/problems/palindrome-number/description/

# @param {Integer} x
# @return {Boolean}
def is_palindrome(x)
  num = x.to_s.split("")
  solution = true
  while num.length > 1 && solution
    unless num.pop == num.shift
      solution = false
      break
    end
  end
  solution
end

def is_palindrome(x)
  num = x.to_s
  vl = num.length / 2
  num.slice(0, vl) == num.slice((num.length - vl), vl).reverse
end

def is_palindrome(x)
  num = x.to_s.split("")
  solution = true
  0.upto(num.length / 2) do |n|
    unless num[n] == num[(-1 - n)]
      solution = false
      break
    end
  end
  solution
end

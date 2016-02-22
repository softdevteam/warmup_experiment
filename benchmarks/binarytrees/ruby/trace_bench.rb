# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org
#
# contributed by Jesse Millikan
# Modified by Wesley Moxam and Michael Klaus


def item_check(left, item, right)
  puts "def item_check(left, item, right)"
  if left.nil? then
    puts "if left.nil? then"
    return item
  end
  item + item_check(*left) - item_check(*right)
end

def bottom_up_tree(item, depth)
  puts "def bottom_up_tree(item, depth)"
  if depth == 0 then
    puts "if depth == 0 then"
    return [nil, item, nil] 
  end
  item_item = 2 * item
  depth -= 1
  [bottom_up_tree(item_item - 1, depth), item, bottom_up_tree(item_item, depth)]
end

def run_iter(max_depth)
    puts "def run_iter(max_depth)"
    #max_depth = ARGV[0].to_i
    min_depth = 4

    max_depth = [min_depth + 2, max_depth].max

    stretch_depth = max_depth + 1
    stretch_tree = bottom_up_tree(0, stretch_depth)

    #puts "stretch tree of depth #{stretch_depth}\t check: #{item_check(*stretch_tree)}"
    stretch_tree = nil

    long_lived_tree = bottom_up_tree(0, max_depth)

    base_depth = max_depth + min_depth
    min_depth.step(max_depth + 1, 2) do |depth|
      puts "min_depth.step(max_depth + 1, 2) do |depth|"
      iterations = 2 ** (base_depth - depth)

      check = 0

      for i in 1..iterations
        puts "for i in 1..iterations"
        temp_tree = bottom_up_tree(i, depth)
        check += item_check(*temp_tree)

        temp_tree = bottom_up_tree(-i, depth)
        check += item_check(*temp_tree)
      end

      #puts "#{iterations * 2}\t trees of depth #{depth}\t check: #{check}"
    end

    #puts "long lived tree of depth #{max_depth}\t check: #{item_check(*long_lived_tree)}"
end

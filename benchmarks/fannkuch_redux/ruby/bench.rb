# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
# Contributed by Wesley Moxam

@EXPECT_CKSUM = 1616
@MAX_N = 8

def run_iter(n)
  for i in 1..n do
    inner_iter()
  end
end

def inner_iter()
  n = @MAX_N
  sign, maxflips, sum = 1, 0, 0

  p = [nil].concat((1..n).to_a)
  q = p.dup
  s = p.dup

  while(true)
    # Copy and flip.
    q1 = p[1]				# Cache 1st element.
    if q1 != 1
      q = p.dup
      flips = 1
      while(true)
	      qq = q[q1]
	      if qq == 1				# ... until 1st element is 1.
	        sum = sum + sign * flips
	        maxflips = flips if flips > maxflips # New maximum?
	        break
	      end
	      q[q1] = q1
	      if q1 >= 4
	        i, j = 2, q1 - 1
	        begin
            q[i], q[j] = q[j], q[i]
            i = i + 1
            j = j - 1
          end while i < j
	      end
	      q1 = qq
        flips = flips + 1
      end
    end
    # Permute.
    if sign == 1
      # Rotate 1<-2.
      p[1], p[2] = p[2], p[1]
      sign = -1	
    else
      # Rotate 1<-2 and 1<-2<-3.
      p[2], p[3] = p[3], p[2]
      sign = 1
      3.upto(n) do |i|
        (s[i] =  s[i] - 1) && break unless s[i] == 1
              if i == n then
	        if sum != @EXPECT_CKSUM then
                  puts("bad checksum: %d vs %d" % [sum, @EXPECT_CKSUM])
                  exit 1
                end
	        return [sum, maxflips] # Out of permutations.
              end
	      s[i] = i
        # Rotate 1<-...<-i+1.
	      t = p[1]
        1.upto(i) do |j|
          p[j] = p[j+1]
        end
        p[i+1] = t
      end
    end
  end
end

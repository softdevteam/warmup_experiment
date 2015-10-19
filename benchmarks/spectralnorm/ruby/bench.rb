# The Computer Language Shootout
# http://shootout.alioth.debian.org/
# Contributed by Sokolov Yura

@SPECTRAL_N = 1000
@EXPECT_CKSUM = 1.2742241481294835914184204739285632967948913574218750

def eval_A(i,j)
	return 1.0/((i+j)*(i+j+1)/2+i+1)
end

def eval_A_times_u(u)
        v, i = nil, nil
	(0..u.length-1).collect { |i|
                v = 0
		for j in 0..u.length-1
			v += eval_A(i,j)*u[j]
                end
                v
        }
end

def eval_At_times_u(u)
	v, i = nil, nil
	(0..u.length-1).collect{|i|
                v = 0
		for j in 0..u.length-1
			v += eval_A(j,i)*u[j]
                end
                v
        }
end

def eval_AtA_times_u(u)
	return eval_At_times_u(eval_A_times_u(u))
end

def run_iter(n)
    for i in 1..n
        checksum = inner_iter(@SPECTRAL_N)
        if checksum != @EXPECT_CKSUM
            puts("bad checksum: %f vs %f" % [checksum, @EXPECT_CKSUM])
            exit(1)
        end
    end
end

def inner_iter(n)
    u=[1]*n
    for i in 1..10
            v=eval_AtA_times_u(u)
            u=eval_AtA_times_u(v)
    end
    vBv=0
    vv=0
    for i in 0..n-1
            vBv += u[i]*v[i]
            vv += v[i]*v[i]
    end
    Math.sqrt(vBv/vv)
end

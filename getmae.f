        subroutine getmae(f1,w1,f2,w2,n,bias,mean1,var1,mean2,var2,mae)
        implicit none
        integer n
        real f1(n),w1(n),f2(n),w2(n),bias,mean1,var1,mean2,var2,mae
        integer i
        real ww1,ww2,ww12
        if ( n.lt.1 ) then
            mean1 = 3e33
            mean2 = 3e33
            bias = 3e33
            var1 = 3e33
            var2 = 3e33
            mae = 3e33
            return
        end if
        mean1 = 0
        mean2 = 0
        ww1 = 0
        ww2 = 0
        do i=1,n
            mean1 = mean1 + w1(i)*f1(i)
            ww1 = ww1 + w1(i)
            mean2 = mean2 + w2(i)*f2(i)
            ww2 = ww2 + w2(i)
        enddo
        mean1 = mean1/ww1
        mean2 = mean2/ww2
        bias = mean1 - mean2
        if ( n.lt.2 ) then
            var1 = 3e33
            var2 = 3e33
            mae = 3e33
            return
        end if
        var1 = 0
        var2 = 0
        mae = 0
        ww12 = 0
        do i=1,n
            var1 = var1 + w1(i)*(f1(i)-mean1)**2
            var2 = var2 + w2(i)*(f2(i)-mean2)**2
            mae = mae + sqrt(w1(i)*w2(i))*abs(f1(i)-f2(i))
            ww12 = ww12 + sqrt(w1(i)*w2(i))
        enddo
        var1 = var1/ww1
        var2 = var2/ww2
        mae = mae/ww12
        end

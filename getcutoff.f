*  #[ getcutoff:
        subroutine getcutoff(cut,pcut,dat,npermax,nperyear,yrbeg,yrend
     +        ,yr1,yr2,j1,j2,lag)
*
*       compute the cut-off in absolute units given a cut-off as a
*       percentage (pcut), data and the range over which the data 
*       should be considered
*       14-jan-2002
*       If the data is daily, a 5-day window is considered.
*
        implicit none
        integer npermax,nperyear,yrbeg,yrend,yr1,yr2,j1,j2,lag
        real cut,pcut,dat(npermax,yrbeg:yrend)
*
        integer yr,jj,m,j,i,ii,n,k,kdif,nmax
        real x
        real,allocatable :: a(:)
        logical lwrite
        parameter (lwrite=.false.)
*
*       for daily data, smooth by considering two days on either side
        if ( nperyear.eq.366 ) then
            kdif = 2
        else
            kdif = 0
        endif
*
*       get linear array with data
        nmax = 12000
 10     continue
        allocate(a(nmax))
        n = 0
        do i=yr1,yr2
            do j=j1,j2
                do k=j-kdif,j+kdif
                    m = k-lag
                    call normon(m,i,ii,nperyear)
                    if ( ii.lt.yrbeg .or.ii.gt.yrend ) goto 710
                    if ( dat(m,ii).lt.1e33 ) then
                        n = n+1
                        if ( n.gt.nmax ) then
                            deallocate(a)
                            nmax = 2*nmax
                            goto 10
                        endif
                        a(n) = dat(m,ii)
                    endif
  710               continue
                enddo
            enddo
        enddo
        call getcut(cut,pcut,n,a)
        deallocate(a)           ! dont forget...
        if ( lwrite ) then
            print *,'getcutoff: pcut          = ',pcut
            print *,'           yr1,yr2,j1,j2 = ',yr1,yr2,j1,j2
            print *,'           lag           = ',lag
            print *,'           cut           = ',cut
        endif
        end
*  #] getcutoff:
*  #[ getcut:
        subroutine getcut(cut,pcut,n,a)
        implicit none
*
*       the other half - break to be able to tie in getmomentsfield
*
        integer n
        real cut,pcut,a(n)
*
        integer i
	logical lwrite
	parameter (lwrite=.false.)
*
	if ( lwrite ) then
            print *,'getcut: pcut,n = ',pcut,n
            do i=1,3
                print *,i,a(i)
            enddo
	endif
*       sort (Numerical Recipes quicksort)
        call nrsort(n,a)
        call getcut1(cut,pcut,n,a,lwrite)
        end
*  #] getcut:
*  #[ getcut1:
        subroutine getcut1(cut,pcut,n,a,lwrite)
*
*       this entry point assumes the array a has already been sorted
*
        implicit none
        integer n
        real cut,pcut,a(n)
        logical lwrite
        real eps
        parameter (eps=1e-5)
        integer i
        real x
        if ( n.le.1 ) then
            cut = 3e33
            return
        endif
*       find elements around pcut
        x = pcut/100*n + 0.5
        i = nint(x)
	if ( lwrite ) print *,'x,i,a(i),a(i+1) = ',
     +       x,i,a(max(i,n)),a(min(i-1,1))
        if ( abs(x-i).lt.eps ) then
*           exact hit, demand unambiguous results
            if ( pcut.lt.50 ) then
                cut = a(i)*(1+eps)
            else
                cut = a(i)*(1-eps)
            endif
        else
*           interpolate
            i = int(x)
            x = x - i
            if ( i.lt.1 ) then
                cut = (2-x)*a(1) + (x-1)*a(2)
            elseif ( i.gt.n-1 ) then
                cut = -x*a(n-1) + (1+x)*a(n)
            else
                cut = (1-x)*a(i) + x*a(i+1)
            endif
        endif
	if ( lwrite ) print *,'getcut: cut = ',cut
        end
*  #] getcut1:
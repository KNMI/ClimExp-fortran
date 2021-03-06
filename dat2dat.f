        program dat2dat
*
*       convert KD De Bilt file to my format
*
        implicit none
        integer nmax
        parameter (nmax=100)
        integer i,j,iselect,istation,idate,ii(nmax),data(12),iyear,yrfac
        character*80 string
        integer iargc
*
        if ( iargc().ne.1 ) then
            print *,'usage: dat2dat [1|2] < infile > outfile.dat'
            stop
        endif
        call getarg(1,string)
        read(string,*) iselect
        if ( iselect.gt.nmax ) then
            print *,'error: can only handle iselect < ',nmax,' not '
     +            ,iselect
            call abort
        endif
*
        read(*,'(a)') string
        print '(a)',string
        print '(a,i4)','# selected column ',iselect
        print *,' '
        print *,' '
        print *,' '
*
        do i=1,12
            data(i) = 9999
        enddo
        iyear = -1
   20   continue
        read (*,*,err=900,end=100) istation,idate,(ii(i),i=1,iselect)
        if ( idate.gt.18000000 .and. idate.lt.21000000 ) then
            yrfac = 10000
        elseif ( idate.gt.180000 .and. idate.lt.210000 ) then
            yrfac = 100
        else
            print *,'error: cannot interpret date ',idate
            call abort
        endif
        if ( idate/yrfac.ne.iyear ) then
            if ( iyear.ne.-1 ) then
                print '(i5,12f8.1)',iyear,(data(i)/10.,i=1,12)
                do i=1,12
                    data(i) = 9999
                enddo
            endif
            iyear = idate/yrfac
        endif
        i = mod(idate,yrfac)/(yrfac/100)
        data(i) = ii(iselect)
        goto 20
  100   continue
        if ( iyear.ne.-1 ) print '(i5,12f8.1)',iyear,(data(i)/10.,
     +            i=1,12)
*
        stop
  900   print *,'error reading data'
        end

        subroutine allday2period(
     +       olddata,mpermax,nperyear,
     +       newdata,npermax,nperyearnew,
     +       yrbeg,yrend,oper,lgt,cut,minfac,itype,var,units,lwrite)
        implicit none
        integer mpermax,nperyear,npermax,nperyearnew,yrbeg,yrend,itype
        real olddata(mpermax,yrbeg:yrend),newdata(npermax,yrbeg:yrend),
     +      cut(mpermax),minfac
        character oper*3,lgt*1,var*(*),units*(*)
        logical lwrite
        integer j,jj,j1,jold,mo,n,dpm(12),dpm365(12)
        data dpm   / 31,29,31,30,31,30,31,31,30,31,30,31/
        data dpm365/ 31,28,31,30,31,30,31,31,30,31,30,31/
*
        if ( nperyearnew.eq.-1 ) then
            if ( nperyear.lt.365 ) then
                j1 = 1 + nperyear/2
            else if ( nperyear.eq.365 ) then
                j1 = 182        ! 1 July
            else if ( nperyear.eq.366 ) then
                j1 = 183        ! 1 July including Feb 29
            else
                write(0,*) 'allday2period: error: cannot handle '//
     +               'shifted annual data for sub-daily data yet'
                call abort
            end if
            call day2period(
     +           olddata,mpermax,nperyear,
     +           newdata,npermax,abs(nperyearnew),
     +           yrbeg,yrend,j1,j1+nperyear-1,1,oper,lgt,cut,
     +           minfac,itype,lwrite)
        else if ( nperyearnew.eq.1 ) then
            call day2period(
     +           olddata,mpermax,nperyear,
     +           newdata,npermax,nperyearnew,
     +           yrbeg,yrend,1,nperyear,1,oper,lgt,cut,
     +           minfac,itype,lwrite)
        elseif ( nperyearnew.eq.4 ) then
            if ( nperyear.ne.360 ) then
                j = -31
            else
                j = -30
            endif
            jold = nint(j/(366./nperyear))
            do mo=0,11
                if ( nperyear.eq.360 ) then
                    j = j + 30
                    jj = j
                elseif ( nperyear.eq.365 ) then
                    if ( mo.gt.0 ) then
                        j = j + dpm365(mo)
                    else
                        j = j + dpm365(mo+12)
                    endif
                    jj = nint(j/(365./nperyear))
                else
                    if ( mo.gt.0 ) then
                        j = j + dpm(mo)
                    else
                        j = j + dpm(mo+12)
                    endif
                    jj = nint(j/(366./nperyear))
                endif
                if ( mo.eq.2 .or. mo.eq.5 .or. mo.eq.8 .or. mo.eq.11 )
     +               then
                    call day2period(
     +                   olddata,mpermax,nperyear,
     +                   newdata,npermax,nperyearnew,
     +                   yrbeg,yrend,jold+1,jj,1+mo/3,oper,lgt,cut,
     +                   minfac,itype,lwrite)
                    jold = jj
                endif
            enddo
        elseif ( nperyearnew.eq.12 ) then
            j = 0
            jold = 0
            do mo=1,12
                if ( nperyear.eq.360 ) then
                    j = j + 30
                    jj = j
                elseif ( nperyear.eq.365 ) then
                    j = j + dpm365(mo)
                    jj = nint(j/(365./nperyear))
                else
                    j = j + dpm(mo)
                    jj = nint(j/(366./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,mo,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
            enddo
        elseif ( nperyearnew.eq.24 ) then
            j = 0
            jold = 0
            do mo=1,12
                j = j + 15
                if ( nperyear.eq.360 .or. nperyear.eq.366 ) then
                    jj = j
                else
                    jj = nint(j/(365./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,2*mo-1,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
                if ( nperyear.eq.360 ) then
                    j = j + 15
                    jj = j
                elseif ( nperyear.eq.365 ) then
                    j = j + dpm365(mo) - 15
                    jj = j
                elseif ( nperyear.eq.366 ) then
                    j = j + dpm(mo) - 15
                    jj = j
                else
                    j = j + dpm(mo) - 15
                    jj = nint(j/(365./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,2*mo,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
            enddo
        elseif ( nperyearnew.eq.36 ) then
            j = 0
            jold = 0
            do mo=1,12
                j = j + 10
                if ( nperyear.eq.360 .or. nperyear.eq.366 ) then
                    jj = j
                else
                    jj = nint(j/(365./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,3*mo-2,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
                j = j + 10
                if ( nperyear.eq.360 .or. nperyear.eq.366 ) then
                    jj = j
                else
                    jj = nint(j/(365./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,3*mo-1,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
                if ( nperyear.eq.360 ) then
                    j = j + 10
                    jj = j
                elseif ( nperyear.eq.365 ) then
                    j = j + dpm365(mo) - 20
                    jj = j
                elseif ( nperyear.eq.366 ) then
                    j = j + dpm(mo) - 20
                    jj = j
                else
                    j = j + dpm(mo) - 20
                    jj = nint(j/(365./nperyear))
                endif
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,jold+1,jj,3*mo,oper,lgt,cut,
     +               minfac,itype,lwrite)
                jold = jj
            enddo
        else
            n = nint(real(nperyear)/real(nperyearnew))
            if ( lwrite ) then
                print *,'allday2period: nperyear,nperyearnew,n = '
     +               ,nperyear,nperyearnew,n
            end if
            do j=1,nperyearnew
                call day2period(
     +               olddata,mpermax,nperyear,
     +               newdata,npermax,nperyearnew,
     +               yrbeg,yrend,n*(j-1)+1,n*j,j,oper,lgt,cut,
     +               minfac,itype,lwrite)
            enddo
        endif
*
        call adjustvar(oper,var,lwrite)
        call adjustunits(oper,nperyear,nperyearnew,units,lwrite)
*
        end

        subroutine day2period(
     +       olddata,nperold,nperyear,
     +       newdata,npernew,nperyearnew,
     +       yrbeg,yrend,j1,j2,jnew,oper,lgt,cut,
     +       minfac,itype,lwrite)
*
*       operates on olddata (j1:j2,) to make newdata(jnew,)
*       oper = mean|sd|min|max|num|sum|nti|xti|fti|lti
*       lgt  = ' '|<|>
*       cut  = cut-off
*       itype=0 scalar data
*       itype>0 direction data, one cycle = itype units
*
*       15-jun-2004 also compute mean when there are missing data
*
        implicit none
        integer nperold,nperyear,npernew,nperyearnew,yrbeg,yrend,
     +          j1,j2,jnew,itype,ntot
        real olddata(nperold,yrbeg:yrend),newdata(npernew,yrbeg:yrend),
     +          cut(nperold),minfac
        character oper*3,lgt*1
        logical lwrite
        integer mo,yr,i,j,n,nn,offset,lfirst
        double precision s,s2,sx,sy,st,s1
*
        if ( lwrite ) then
            print *,'day2period: parameters are '
            print *,'nperold,nperyear    = ',nperold,nperyear
            print *,'npernew,nperyearnew = ',npernew,nperyearnew
            print *,'yrbeg,yrend         = ',yrbeg,yrend
            print *,'j1,j2,jnew          = ',j1,j2,jnew
            print *,'oper,lgt            = ',oper,lgt
            print *,'itype               = ',itype
            if ( lgt.ne.' ' ) then
                print *,'cut                 = '
                print *,(cut(j),j=1,nperyear)
            endif
            print *,'olddata             = '
            do yr=yrbeg,yrend
                do mo=j1,j2
                    j = mo
                    call normon(j,yr,i,nperyear)
                    if ( yrbeg.eq.0 .and. yrend.eq.0 ) i = 0
                    if ( i.lt.yrbeg ) cycle
                    if ( olddata(j,i).lt.1e33 ) then
                        print *,i,j,olddata(j,i)
                    endif
                enddo
            enddo
        endif
        if ( itype.ne.0 .and. (oper.eq.'min' .or. oper.eq.'max' .or.
     +       oper.eq.'nti' .or. oper.eq.'xti' .or.oper.eq.'fti' .or. 
     +       oper.eq.'lti' .or. oper.eq.'sd' .or. oper.eq.'con') ) then
            write(0,*)
     +            'day2period: cannot take min,max,sd of vector data'
            write(*,*)
     +            'day2period: cannot take min,max,sd of vector data'
            call abort
        endif
*
        do yr=yrbeg,yrend
            if ( oper.eq.'mea' .or. oper.eq.'sd ' .or. 
     +           oper.eq.'sum' .or. 
     +           oper.eq.'bel' .or. oper.eq.'abo' .or.
     +           oper.eq.'con' ) then
                if ( itype.eq.0 ) then
                    s = 0
                else
                    sx = 0
                    sy = 0
                endif
                if ( oper.eq.'sd ' ) s2 = 0
            elseif ( oper.eq.'min' .or. oper.eq.'nti' ) then
                if ( itype.eq.0 ) then
                    s = 3e33
                else
                    sx = 3e33
                    sy = 3e33
                endif
            elseif ( oper.eq.'max' .or. oper.eq.'xti' ) then
                if ( itype.eq.0 ) then
                    s = -3e33
                else
                    sx = -3e33
                    sy = -3e33
                endif
            endif
            s1 = 0              ! current run of consecutive periods
            st = 3e33           ! time of min/max/first/last
            n = 0
            ntot = 0
            lfirst = 9999
            offset = 0
            do mo=j1,j2
                j = mo
                call normon(j,yr,i,nperyear)
                if ( yrbeg.eq.0 .and. yrend.eq.0 ) i = yr
                if ( i.lt.yrbeg .or. i.gt.yrend ) cycle
*               skip Feb 29
                nn = nperyear/366
                if ( 366*nn.eq.nperyear .and. j.eq.60*nn .and. 
     +                  olddata(j,i).gt.1e33 ) then
                    offset = offset - 1
                    cycle
                end if
*               but generate an "invalid" for any other invalid data
*               [this may be relaxed later...]
                if ( olddata(j,i).gt.1e33 ) then
***                 newdata(jnew,i) = 3e33
                    cycle
                endif
                ntot = ntot + 1
                if ( lfirst.eq.9999 ) lfirst = mo-j1
                if ( lgt.eq.' ' .or.
     +               lgt.eq.'<' .and. olddata(j,i).lt.cut(j) .or.
     +               lgt.eq.'>' .and. olddata(j,i).gt.cut(j) ) then
                    n = n + 1
                    if ( oper.eq.'fti' ) then
                        if ( st.eq.3e33 ) st = mo - 0.5 + offset
                    else if ( oper.eq.'lti' ) then
                        st = mo - 0.5 + offset
                    else if ( oper.eq.'mea' .or. oper.eq.'sum' .or. 
     +                    oper.eq.'sd ' ) then
                        if ( itype.eq.0 ) then
                            s = s + olddata(j,i)
                        else
                            sx = sx + cos(8*atan(1.)*olddata(j,i)/itype)
                            sy = sy + sin(8*atan(1.)*olddata(j,i)/itype)
                        endif
                        if ( oper.eq.'sd ' ) then
                            s2 = s2 + olddata(j,i)**2
                        endif
                    elseif ( oper.eq.'abo' ) then
                        s = s + olddata(j,i)-cut(j)
                    elseif ( oper.eq.'bel' ) then
                        s = s + cut(j)-olddata(j,i)
                    elseif ( oper.eq.'min' .or. oper.eq.'nti' ) then
                        if ( olddata(j,i).lt.s ) then
                            s = olddata(j,i)
                            st = mo - 0.5 + offset
                        end if
                    elseif ( oper.eq.'max' .or. oper.eq.'xti' ) then
                        if ( olddata(j,i).gt.s ) then
                            s = olddata(j,i)
                            st = mo - 0.5 + offset
                        end if
                    elseif ( oper.eq.'con' ) then
                        s1 = s1 + 1
                        s = max(s,s1)
                    endif
                    if ( lwrite ) print *,'partial sum: ',j,n,s
                else
                    if ( oper.eq.'con' ) then
                        s1 = 0
                    end if
                    if ( lwrite ) print *,j,olddata(j,i),lgt,cut(j)
                endif
            enddo
            if ( lwrite .and. lfirst.lt.9999 ) write(0,*)
     +           yr,'lfirst,minfac*(j2-j1+1) = ',lfirst,minfac*(j2-j1+1)
            if ( lfirst.gt.minfac*(j2-j1+1) .or.
     +           ntot.lt.minfac*nperyear/nperyearnew ) then
                newdata(jnew,yr) = 3e33            
            elseif ( n.eq.0 .and. 
     +               (oper.eq.'mea' .or. oper.eq.'min' .or. 
     +               oper.eq.'max' .or. oper.eq.'nti' .or. 
     +               oper.eq.'xti' .or. oper.eq.'fti' .or.
     +               oper.eq.'lti' ) ) then
                newdata(jnew,yr) = 3e33
            elseif ( oper.eq.'mea' ) then
                if ( itype.eq.0 ) then
                    if ( lwrite ) print *,'s,n,s/n = ',s,n,s/n
                    newdata(jnew,yr) = s/n
                else
                    if ( lwrite ) then
                        print *,'sx,n,sx/n = ',sx,n,sx/n
                        print *,'sy,n,sy/n = ',sy,n,sy/n
                        print *,'atan2(sy,sx)',atan2(sy,sx)
                    endif
                    newdata(jnew,yr) = itype*atan2(sy,sx)/(8*atan(1.))
                    if ( newdata(jnew,yr).lt.0 ) newdata(jnew,yr) =
     +                    newdata(jnew,yr) + itype
                endif
            elseif ( oper.eq.'sd ' ) then
*               numerically not very stable, should be improved as soon
*               as I get pressure data
!               promoted s,s2 to double precision, should solve this
                newdata(jnew,yr) = sqrt(s2/n - (s/n)**2)
            elseif ( oper.eq.'sum' .or. oper.eq.'bel' .or. oper.eq.'abo'
     +                .or. oper.eq.'min' .or. oper.eq.'max' ) then
                if ( itype.eq.0 ) then
                    newdata(jnew,yr) = s
                else
                    newdata(jnew,yr) = itype*atan2(sy,sx)/(8*atan(1.))
                    if ( newdata(jnew,yr).lt.0 ) newdata(jnew,yr) =
     +                    newdata(jnew,yr) + itype
                endif
            elseif ( oper.eq.'nti' .or. oper.eq.'xti' .or.
     +               oper.eq.'fti' .or. oper.eq.'lti' ) then
                newdata(jnew,yr) = st
            elseif ( oper.eq.'num' ) then
                newdata(jnew,yr) = n
            elseif ( oper.eq.'con' ) then
                newdata(jnew,yr) = s
            else
                write(0,*) 'day2period: error: unknown operation ',oper
                call abort
            endif
            if ( lwrite) then
                print *,'day2period: computed newdata'
***             if ( newdata(i,yr).lt.1e33 ) then
                    print *,yr,jnew,newdata(jnew,yr)
***             endif
            endif
  100       continue
        enddo
        end
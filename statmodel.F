        program statmodel
*
*       construct an empirical seasonal forecast model
*       and output the data in a format sitable for the
*       U.Reading R routines (i.e., only the data of interest)
*
        implicit none
#include "netcdf.inc"
#include "getopts.inc"
#include "params.h"
        integer status,ncid,nx,ny,nz,nt,nperyear,firstyr
     +       ,firstmo,nvars,ivars(2,3),jvars(6,3),endian,
     +       ncid1,nx1,ny1,nz1,nt1,nperyear1,firstyr1
     +       ,firstmo1,nvars1,ivars1(2,3),jvars1(6,3),endian1,
     +       nx2,ny2
        integer yr,mo,i,j,k,n,if,nxf,nyf
     +       ,lag,irec,iu,sum,mana,nfcstens,mens1,mens,lastyr,iens
     +       ,mobegin,ntvarid,nonc,mstart,mstartseries,mstartfield,x1,x2
     +       ,y1,y2,yrstart,yrstop,lsumseries,lsumfield
        integer,allocatable :: itimeaxis(:)
        real xx(nxmax),yy(nymax),zz(nzmax),undef,tarray(2),f,u,wx(nxmax)
     +       ,wy(nymax),xx1(nxmax),yy1(nymax),zz1(nzmax),undef1,
     +       xx2(nxmax),yy2(nymax)
        real,allocatable :: field(:,:,:,:,:),field1(:,:,:,:,:),
     +       series(:,:,:),series2(:,:,:),obsxy1(:,:,:),obsxy2(:,:,:),
     +       fcstxy(:,:,:),fcst(:,:,:,:,:),obs(:,:,:,:)
        logical lexist,lpersist,lseries,lfield,xrev,yrev,xwrap,llwrite
        character infile*255,datfile*255,seriesfile*255,fieldfile*255,
     +       string*80,title*255,vars(1)*10,lvars(1)*40,units(1)*20,
     +       line*255,var*20,vars1(1)*10,lvars1(1)*40,units1(1)*20
        integer iargc
        real etime
*
*       process arguments
*
        lwrite = .FALSE.
        if ( iargc().lt.6 ) then
            print *,'usage: statmodel field.[ctl|nc] analysis m1 '
     +           //'[no]persistence onc M ensemble N '
     +           //'[series file.dat nseries] '
     +           //'[field  otherfield.[ctl|nc] nfield'
     +           //'[month m2] [sum n1] [sum2 n2] '
     +           //'[begin yr1] [end yr2] [begin2 yr1a] [end2 yr2a] '
     +           //'[detrend] [lon1 x1 lon2 x2 lat1 y1 lat2 y2]'
     +           //'plot output.nc'
            print *,'[no]persistence: use persistence as predictor'
            print *,'onc M: use Optimal Normal Correction of N years'
            print *,'       (0: no ONC)'
            print *,'ensemble N: number of ensemble members to generate'
            print *,'series: the regression on series is used if p<.05'
            print *,'nseries: number of months to sum series over'
            print *,'field: the local regression on field is used p<.05'
            print *,'nfield: number of months to sum field over'
            print *,'m1: analysis month; only use data before the first'
            print *,'    of this month'
            print *,'m2: start of season for which to compute forecasts'
            print *,'n1: number of months in forecast season'
            print *,'n2: number of months in persistence season '//
     +           '(default n1)'
            print *,'yr1,2: only make forecasts from yr1 to yr2'
            print *,'yr1a,2a: only use data from yr1a to yr2a'//
     +           '(default yr1,2)'
            print *,'The forecasts are cross-validated, i.e., for '//
     +           'each year a forecast is model is made from yr1a-yr2a '
     +           //'excluding the year being forecast.'
            stop
        endif
        call killfile(infile,datfile,plotfile,0)
        call getarg(1,infile)
        print '(2a)','# making a model of ',trim(infile)
        if ( index(infile,'%').gt.0 .or. index(infile,'++').gt.0 ) then
            ensemble = .true.
            call filloutens(infile,0)
            inquire(file=infile,exist=lexist)
            if ( .not.lexist ) then
                mens1 = 1
                call filloutens(infile,1)
            else
                mens1 = 0
            endif
        else
            ensemble = .false.
            mens1 = 0
            mens = 0
        endif
        if ( lwrite ) print *,'statmodel: nf_opening file ',trim(infile)
        status = nf_open(infile,nf_nowrite,ncid)
        if ( status.ne.nf_noerr ) then
            call parsectl(infile,datfile,nxmax,nx,xx,nymax,ny,yy,nzmax,nz
     +            ,zz,nt,nperyear,firstyr,firstmo,undef,endian,title,1
     +            ,nvars,vars,ivars,lvars,units)
            ncid = -1
            if ( ensemble ) then
                do mens=1,nensmax
                    call getarg(1,line)
                    call filloutens(line,mens)
                    inquire(file=line,exist=lexist)
                    if ( .not.lexist ) goto 100
                enddo
  100           continue
                mens = mens - 1
                write(0,*) 'located ',mens-mens1+1
     +               ,' ensemble members<br>'
            endif
        else
            if ( lwrite ) print *,'calling parsenc on ',trim(infile)
            call parsenc(infile,ncid,nxmax,nx,xx,nymax,ny,yy,nzmax
     +           ,nz,zz,nt,nperyear,firstyr,firstmo,undef,title,1,nvars
     +           ,vars,jvars,lvars,units)
            if ( ensemble ) then
                do mens=1,nensmax
                    call getarg(1,line)
                    call filloutens(line,mens)
                    status = nf_open(line,nf_nowrite,ncid)
                    if ( status.ne.nf_noerr ) goto 200
                enddo
  200           continue
                mens = mens - 1
                write(0,*) 'located ',mens+1,' ensemble members<br>'
            endif
        endif
*
*       process other options
*
        lastyr = firstyr + (nt+firstmo-2)/nperyear
        call getarg(2,string)
        if ( string(1:3).ne.'ana' ) goto 901
        call getarg(3,string)
        read(string,*,err=902) mana
        print '(a,i2)','# analysis date is beginning of ',mana
        call getarg(4,string)
        if ( string(1:3).eq.'nop' ) then
            lpersist = .FALSE.
            print '(a)','# not including persistence'
        elseif ( string(1:3).eq.'per' ) then
            lpersist = .TRUE.
            print '(a)','# including persistence'
        else
            goto 903
        endif
        call getarg(5,string)
        if ( string(1:3).ne.'onc' ) goto 905
        call getarg(6,string)
        read(string,*,err=905) nonc
        if ( nonc.eq.0 ) then
            print '(a)','# including climatology'
        else
            print '(a,i3,a)'
     +           ,'# including moving-average climatology of ',nonc
     +           ,' years'
        endif
        call getarg(7,string)
        if ( string(1:3).ne.'ens' ) goto 904
        call getarg(8,string)
        read(string,*,err=904) nfcstens
        print '(a,i4,a)','# generating ',nfcstens,' ensemble members'
        call getarg(9,string)
        if ( string(1:6).eq.'series' ) then
            call getarg(10,seriesfile)
            call getarg(11,string)
            read(string,*,err=906) lsumseries
            print '(3a,i2,a)','# including regression to time series '
     +           ,trim(seriesfile),' summed over ',lsumseries,' months'
            lseries = .true.
            n = 12
        else
            lseries = .false.
            lsumseries = 0
            n = 9
        endif
        call getarg(n,string)
        if ( string(1:6).eq.'field' ) then
            call getarg(n+1,fieldfile)
            call getarg(n+2,string)
            read(string,*,err=907) lsumfield
            print '(3a,i2,a)','# including regression to other field '
     +           ,trim(fieldfile),' summed over ',lsumfield,' months'
            lfield = .true.
            n = n + 3
        else
            lfield = .false.
            lsumfield = 0
            mens1 = 0
        endif
        call getopts(n,iargc()-1,nperyear,yrbeg,yrend,.true.,mens1,mens)
        if ( .not.plot .or. plotfile.eq.' ' ) then
            write(0,*) 'statmodel: error: output file is not set with '
     +           //' ''plot file'''
            call abort
        endif
        llwrite = lwrite
***     llwrite = .true.
        yr1a = max(yr1a,firstyr)
        yr2a = min(yr2a,lastyr)
        if ( lpersist ) then
            mstart = mana - lsum2
            if ( mstart.le.0 ) mstart = mstart + nperyear
        else
            mstart = m1
        endif
        if ( lseries ) then
            mstartseries = mana - lsumseries
            if ( mstartseries.le.0 ) mstartseries = mstartseries +
     +           nperyear
        else
            mstartseries = m1
        endif
        if ( lfield ) then
            mstartfield = mana - lsumfield
            if ( mstartfield.le.0 ) mstartfield = mstartfield + nperyear
        else
            mstartfield = m1
        endif
        if ( lwrite ) then
            print *,'mana                            = ',mana
            print *,'lsum2,lsumseries,lsumfield      = ',lsum2
     +           ,lsumseries,lsumfield
            print *,'mstart,mstartseries,mstartfield = ',mstart
     +           ,mstartseries,mstartfield
        endif
        if ( mstart.le.m1 .and. mstartseries.le.m1 
     +       .and. mstartfield.le.m1 ) then
            yr1 = max(yr1,yr1a)
            yr2 = min(yr2,yr2a)
        else
            yr1 = max(yr1,yr1a+1)
            yr2 = min(yr2,yr2a+1)
        endif
        yrstart = yr2
        yrstop  = yr1
        if ( lseries .and. (yr1a.lt.yrbeg .or. yr2a.gt.yrend) ) then
            write(0,*) 'statmodel: error: yr1a-yr2a outside yrbeg-yrend'
     +           ,yr1a,yr2a,yrbeg,yrend
            call abort
        endif
*
*       read metadata second field if requested
*
        if ( lfield ) then
            line = fieldfile
            if ( index(fieldfile,'++') + index(fieldfile,'%%').gt.0 )
     +           then
                mens1 = 1
            else
                mens1 = mens
            endif
            if ( lwrite ) print *,'opening file ',fieldfile
            status = nf_open(fieldfile,nf_nowrite,ncid1)
            if ( status.ne.nf_noerr ) then
                call parsectl(fieldfile,datfile,nxmax,nx1,xx1,nymax,ny1
     +               ,yy1,nzmax,nz1,zz1,nt1,nperyear1,firstyr1,firstmo1
     +               ,undef1,endian1,title,1,nvars1,vars1,ivars1,lvars1
     +               ,units1)
                ncid1 = -1
            else
                if ( lwrite ) print *,'calling parsenc on '
     +               ,trim(fieldfile)
                call parsenc(fieldfile,ncid1,nxmax,nx1,xx1,nymax,ny1,yy1
     +               ,nzmax,nz1,zz1,nt1,nperyear1,firstyr1,firstmo1
     +               ,undef1,title,1,nvars1,vars1,jvars1,lvars1,units1)
            endif
            if ( nperyear1.ne.nperyear ) then
                write(0,*) 'other time scales: ',nperyear,nperyear1
                call abort
            endif
            nxf = max(nx,nx1)
            nyf = max(ny,ny1)
            yr1 = max(yr1,firstyr1)
            yr2 = min(yr2,firstyr1 + (nt1+firstmo1-2)/nperyear1)
            yr1a = max(yr1a,firstyr1)
            yr2a = min(yr2a,firstyr1 + (nt1+firstmo1-2)/nperyear1)
        else
            nxf = nx
            nyf = ny
        endif
*
*       allocate arrays
*
        if ( lwrite ) print *,'allocating arrays, yr1a,yr2a = ',
     +       yr1a,yr2a
        allocate(field(nxf,nyf,1:nperyear,yr1a:yr2a,0:nens2))
        allocate(obsxy1(1:nperyear,yr1a:yr2a,0:nens2))
        allocate(obsxy2(1:nperyear,yr1a:yr2a,0:nens2))
        allocate(fcstxy(1:nperyear,yr1:yr2,nfcstens))
*
*       read field data
*
        if ( lwrite ) print *,'reading field'
        if ( ncid.eq.-1 ) then
            if ( ensemble ) then
                do iens=nens1,nens2
                    call getarg(1,infile)
                    call filloutens(infile,iens)
                    call parsectl(infile,datfile,nxmax,nx,xx,nymax
     +                   ,ny,yy,nzmax,nz,zz,nt,nperyear,if
     +                   ,firstmo,u,endian,title,1,nvars,vars
     +                   ,ivars,lvars,units)
                    call keepalive(iens,nens2-nens1+2)
                    call readdatfile(datfile
     +                   ,field(1,1,1,yr1a,iens)
     +                   ,nxf,nyf,nx,ny,nperyear,yr1a,yr2a
     +                   ,if,firstmo,nt,u,endian,lwrite
     +                   ,max(firstyr,yr1a),min(lastyr,yr2a),1,1)
                 enddo
            else
                call keepalive(1,1)
                call readdatfile(datfile,field,nxf,nyf,nx,ny
     +               ,nperyear,yr1a,yr2a,firstyr,firstmo,nt,undef
     +               ,endian,lwrite,max(firstyr,yr1a),min(lastyr,yr2a)
     +               ,1,1)
            endif
        else
            if ( ensemble ) then
                do iens=nens1,nens2
                    call getarg(1,infile)
                    call filloutens(infile,iens)
                    call parsenc(infile,ncid,nxmax,nx,xx,nymax,ny
     +                   ,yy,nzmax,nz,zz,nt,nperyear,if,firstmo
     +                   ,u,title,1,nvars,vars,jvars,lvars,units)
                    call keepalive(iens,nens2-nens1+2)
                    call readncfile(ncid,field(1,1,1,yr1a,iens),nxf
     +                   ,nyf,nx,ny,nperyear,yr1a,yr2a,if,firstmo,nt,u
     +                   ,lwrite,max(firstyr,yr1a),min(lastyr,yr2a)
     +                   ,jvars)
                enddo
            else
                call keepalive(1,2)
                call readncfile(ncid,field,nxf,nyf,nx,ny,nperyear
     +               ,yr1a,yr2a,firstyr,firstmo,nt,undef,lwrite
     +               ,max(firstyr,yr1a),min(lastyr,yr2a),jvars)
            endif
        endif
*
*       read time series
*
        allocate(series(1:nperyear,yrbeg:yrend,0:nens2))
        if ( lseries ) then
            if ( lwrite ) print *,'reading series'
            call readensseries(seriesfile,series,nperyear,yrbeg,yrend
     +           ,nens2,n,mens1,mens,var,units,.false.,lwrite)
            if ( n.ne.nperyear ) then
                write(0,*) 'statmodel: error: series should have the ',
     +               'same time resolution as field, not ',n,nperyear
                call abort
            endif
*           average over lsumseries months
            do iens=nens1,nens2
                call sumit(series(1,yrbeg,iens),nperyear,nperyear,yrbeg
     +               ,yrend,lsumseries,'v')
            enddo
        endif
*
*       read second field and interpolate to grid of first one
*
        if ( lfield ) then
            allocate(field1(nxf,nyf,1:nperyear,yr1a:yr2a,0:nens2))
            if ( lwrite ) print *,'reading field1'
            if ( ncid.eq.-1 ) then
                if ( mens1.gt.0 ) then
                    do iens=nens1,nens2
                        fieldfile = line
                        call filloutens(fieldfile,iens)
                        call parsectl(fieldfile,datfile,nxmax,nx1,xx1
     +                       ,nymax,ny1,yy1,nzmax,nz1,zz1,nt1,nperyear1
     +                       ,if,firstmo1,u,endian1,title,1,nvars1,vars1
     +                       ,ivars1,lvars1,units1)
                        call keepalive(iens,nens2-nens1+2)
                        call readdatfile(datfile
     +                       ,field1(1,1,1,yr1a,iens)
     +                       ,nxf,nyf,nx1,ny1,nperyear,yr1a,yr2a
     +                       ,if,firstmo1,nt1,u,endian1,lwrite
     +                       ,max(firstyr,yr1a),min(lastyr,yr2a),1,1)
                    enddo
                else
                    call keepalive(1,1)
                    call readdatfile(datfile,field,nxf,nyf,nx1,ny1
     +                   ,nperyear,yr1a,yr2a,firstyr1,firstmo1,nt1
     +                   ,undef1,endian1,lwrite,max(firstyr,yr1a)
     +                   ,min(lastyr,yr2a),1,1)
                endif
            else
                if ( ensemble ) then
                    do iens=nens1,nens2
                        fieldfile = line
                        call filloutens(fieldfile,iens)
                        call parsenc(fieldfile,ncid1,nxmax,nx1,xx1,nymax
     +                       ,ny1,yy1,nzmax,nz1,zz1,nt1,nperyear1,if
     +                       ,firstmo1,u,title,1,nvars1,vars1,jvars1
     +                       ,lvars1,units1)
                        call keepalive(iens,nens2-nens1+2)
                        call readncfile(ncid1,field1(1,1,1,yr1a,iens)
     +                       ,nxf,nyf,nx1,ny1,nperyear,yr1a,yr2a,if
     +                       ,firstmo1,nt1,u,lwrite,max(firstyr,yr1a)
     +                       ,min(lastyr,yr2a),jvars1)
                    enddo
                else
                    call keepalive(1,2)
                    call readncfile(ncid1,field1,nxf,nyf,nx1,ny1
     +                   ,nperyear,yr1a,yr2a,firstyr1,firstmo1,nt1
     +                   ,undef1,lwrite,max(firstyr,yr1a),min(lastyr
     +                   ,yr2a),jvars1)
                endif
            endif
            call interpu(field1,xx1,yy1,nx1,ny1,
     +           field,xx,yy,nx,ny, xx2,nx2,yy2,ny2,
     +           yr1a,yr2a,yr1a,yr2a,nxf,nyf,nperyear,2,.false.)
            call checkgridequal(nx,ny,xx,yy,nx2,ny2,xx2,yy2)
        endif
        allocate(series2(1:nperyear,yr1a:yr2a,0:mens1))
*
*       cut out region
*
        if ( lfield ) then
            call getxyprop(xx2,nx2,yy2,ny2,xrev,yrev,xwrap)
            call getlatlonwindow(lat1,lat2,lon1,lon2,xx2,nx2,xwrap,1,yy2
     +           ,ny2,1,x1,x2,y1,y2,lwrite)
            call enscutoutwindow(x1,x2,y1,y2,xx2,nx2,xwrap,xrev,1,yy2,ny2
     +           ,1,wx,wy,field1,nx2,ny2,nens1,nens2,nperyear,yr1a,yr2a
     +           ,max(firstyr,yr1a),min(lastyr,yr2a),lwrite)
        endif
        call getxyprop(xx,nx,yy,ny,xrev,yrev,xwrap)
        call getlatlonwindow(lat1,lat2,lon1,lon2,xx,nx,xwrap,1,yy
     +        ,ny,1,x1,x2,y1,y2,lwrite)
        call enscutoutwindow(x1,x2,y1,y2,xx,nx,xwrap,xrev,1,yy,ny
     +       ,1,wx,wy,field,nx,ny,nens1,nens2,nperyear,yr1a,yr2a
     +       ,max(firstyr,yr1a),min(lastyr,yr2a),lwrite)
        if ( lfield ) then
            call checkgridequal(nx,ny,xx,yy,nx2,ny2,xx2,yy2)
        endif
!
!       allocate result arrays (can be much smaller)
!
        if ( m1.eq.m2 ) then
            allocate(fcst(nx,ny,1,yr1:yr2,nfcstens))
            allocate(obs(nx,ny,1,yr1:yr2))
        else
            allocate(fcst(nx,ny,1:nperyear,yr1:yr2,nfcstens))
            allocate(obs(nx,ny,1:nperyear,yr1:yr2))
        endif
*
*       loop over grid points
*
        do j=1,ny
            call keepalive(j,ny)
            if ( lwrite ) write(0,*) j,'/',ny,etime(tarray)
            do i=1,nx
                if ( lwrite ) print *,'grid point ',i,j,xx(i),yy(j)
*
*               extract linear time series
*
                obsxy1(1:nperyear,yr1a:yr2a,nens1:nens2) = 
     +               field(i,j,1:nperyear,yr1a:yr2a,nens1:nens2)
                if ( lsum2.ne.lsum ) then
                    obsxy2 = obsxy1
                endif
*
*               average over lsum,lsum2 months
*
                do iens=nens1,nens2
                    call sumit(obsxy1(1,yr1a,iens),nperyear,nperyear
     +                   ,yr1a,yr2a,lsum,'v')
                    if ( lsum2.ne.lsum ) then
                        call sumit(obsxy2(1,yr1a,iens),nperyear,nperyear
     +                       ,yr1a,yr2a,lsum2,'v')
                    endif
                enddo
                if ( lsum2.eq.lsum ) then
                    obsxy2 = obsxy1
                endif
                if ( m1.eq.m2 ) then
                    do yr=yr1,yr2
                        if ( yr.ge.yr1a .and. yr.le.yr2a ) then
                            obs(i,j,1,yr) = obsxy1(m1,yr,nens1)
                        else
                            obs(i,j,1,yr) = 3e33
                        endif
                    enddo
                else
                    do yr=yr1,yr2
                        if ( yr.ge.yr1a .and. yr.le.yr2a ) then
                            obs(i,j,:,yr) = obsxy1(:,yr,nens1)
                        else
                            obs(i,j,:,yr) = 3e33
                        endif
                    enddo
                endif
                if ( lfield ) then
                    if ( mens1.eq.0 ) then
                        series2(1:nperyear,yr1a:yr2a,0) = 
     +                       field1(i,j,1:nperyear,yr1a:yr2a,0)
                        if ( lsumfield.ne.1 ) then
*                           average over lsum2 months
                            call sumit(series2(1,yr1a,0),nperyear
     +                           ,nperyear,yr1a,yr2a,lsumfield,'v')
                        endif
                        do iens=max(1,nens1),nens2
                            series2(1:nperyear,yr1a:yr2a,iens) = 
     +                           series2(1:nperyear,yr1a:yr2a,0)
                        enddo
                    else
                        series2(1:nperyear,yr1a:yr2a,nens1:nens2) = 
     +                      field1(i,j,1:nperyear,yr1a:yr2a,nens1:nens2)
                        if ( lsum2.ne.1 ) then
*                       average over lsum2 months
                            do iens=nens1,nens2
                                call sumit(series2(1,yr1a,iens)
     +                               ,nperyear,nperyear,yr1a,yr2a
     +                               ,lsumfield,'v')
                            enddo
                        endif
                    endif
                endif
*
*               make forecast timeseries for this point
*
                if ( llwrite ) print *,'calling statmodel1 ',i,j
                call statmodel1(obsxy1,obsxy2,nperyear,
     +               lseries,series(1,yr1a,0),mstartseries,
     +               lfield,series2(1,yr1a,0),mstartfield,
     +               lpersist,nonc,mstart,fcstxy,nfcstens,yrstart,yrstop
     +               )
*
*               and save
*
                if ( m1.eq.m2 ) then
                    fcst(i,j,1,yr1:yr2,1:nfcstens) =
     +                   fcstxy(m1,yr1:yr2,1:nfcstens)
                    if ( llwrite ) then
                        do yr=yr1,yr2
                            print *,yr,fcst(i,j,1,yr,:)
                        enddo
                    endif
                else
                    fcst(i,j,1:nperyear,yr1:yr2,1:nfcstens) =
     +                   fcstxy(1:nperyear,yr1:yr2,1:nfcstens)
                endif
            enddo
        enddo
*
*       write output
*
        if ( lwrite ) print *,'yr1,yr2 = ',yr1,yr2
        nt = (yr2-yr1+1)
        if ( m1.ne.m2 .or. nperyear.gt.12 ) nt = nt*nperyear
        allocate(itimeaxis(nt))
        if ( nz.gt.1 ) then
            write(0,*) 'statmodel: error: cannot handle '//
     +           'nz>1 yet: ',nz
            call abort
        else
            nz = 1
            ivars(1,1) = 0
        endif
        if ( m1.ne.m2 .or.nperyear.gt.12 ) then
            mobegin = 1
        else
            mobegin = m1
            nperyear = 1
        endif
*
*       forecasts
*
        if ( lwrite ) print *,'writing forecasts'
        title = 'statistical model based on '//trim(infile)
        if ( lseries ) title = trim(title)//' and '//trim(seriesfile)
        if ( lseries ) title = trim(title)//' and '//trim(fieldfile)
        call writenc(plotfile,ncid,ntvarid,itimeaxis,nt,nx,xx,ny
     +       ,yy,nz,zz,nt,nperyear,yr1,mobegin,3e33,title,nvars
     +       ,vars,ivars,lvars,units,1,nfcstens)
        do iens=1,nfcstens
            do yr=yr1,yr2
                if ( m1.eq.m2 .and. nperyear.le.12 ) then
                    call writencslice(ncid,ntvarid,itimeaxis,nt
     +                   ,ivars,fcst(1,1,1,yr,iens),nx,ny,nz,nx
     +                   ,ny,nz,yr-yr1+1,iens)
                else
                    do mo=1,nperyear
                        call writencslice(ncid,ntvarid,itimeaxis,nt
     +                       ,ivars,fcst(1,1,mo,yr,iens),nx,ny
     +                       ,nz,nx,ny,nz,mo+nperyear*(yr-yr1),iens)
                    enddo
                endif
            enddo
        enddo        
        i = nf_close(ncid)
*
*       observations
*
        i = index(plotfile,'.nc')
        if ( i.eq.0 ) i = len_trim(plotfile) + 1
        plotfile(i:) = '_obs.nc'
        title = 'observations from '//trim(infile)
        call writenc(plotfile,ncid,ntvarid,itimeaxis,nt,nx,xx,ny
     +       ,yy,nz,zz,nt,nperyear,yr1,mobegin,3e33,title,nvars
     +       ,vars,ivars,lvars,units,0,0)
        do yr=yr1,yr2
            if ( m1.eq.m2 .and. nperyear.le.12 ) then
                call writencslice(ncid,ntvarid,itimeaxis,nt
     +               ,ivars,obs(1,1,1,yr),nx,ny,nz,nx,ny,nz
     +               ,yr-yr1+1,1)
            else
                do mo=1,nperyear
                    call writencslice(ncid,ntvarid,itimeaxis,nt
     +                   ,ivars,obs(1,1,mo,yr),nx,ny,nz,nx
     +                   ,ny,nz,mo+nperyear*(yr-yr1),1)
                enddo
            endif
        enddo
*       essential!
        i = nf_close(ncid)
*
*       and export yrstart, yrstop with interval with valid data
*
        call savestartstop(yrstart,yrstop)
*
*       error messages
*
        goto 999
 901    write(0,*) 'statmodel: error: exepcting ''analysis'', not ',
     +       trim(string)
        call abort
 902    write(0,*) 'statmodel: error: cannot read number 1:12 from ',
     +       trim(string)
        call abort
 903    write(0,*) 'statmodel: error: expected [no]persistence, not '
     +       ,trim(string)
        call abort
 904    write(0,*) 'statmodel: error: expected ensemble N, not '
     +       ,trim(string)
        call abort
 905    write(0,*) 'statmodel: error: expected ''onc'', not '
     +       ,trim(string)
        call abort
 906    write(0,*) 'statmodel: error: expecting umber of months '//
     +       'to sum series over, but got ',trim(string)
        call abort
 907    write(0,*) 'statmodel: error: expecting umber of months '//
     +       'to sum field over, but got ',trim(string)
        call abort
 999    continue
        end

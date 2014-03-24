!       default parameters for the Climate Explorer
        integer nxmax,nymax,nzmax,yrbeg,yrend,nvmax,npermax,ndata         &
     &        ,nensmax,nmodelmax
        parameter (nxmax=1650,nymax=697,nzmax=95,                         &
     &       yrbeg=1000,yrend=2300,nvmax=1,npermax=73,                    &
     &       ndata=npermax*(yrend-yrbeg+1),nensmax=120,                    &
     &       nmodelmax=30)
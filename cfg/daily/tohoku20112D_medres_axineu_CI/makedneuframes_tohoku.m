
indir='~/zettergmdata/simulations.MAGIC/tohoku/'
loc='';
simlab='strong'
outdir='~/zettergmdata/simulations/input/tohoku_neutrals/'
mkdir([outdir]);


%TOHOKU EXAMPLE
ymd0=[2011,3,11];
UTsec0=20783;
dtneu=4;


%LOAD THE DATA FROM AN INPUT SIMULATION
if ~exist('velx')
    load([indir,'/velx',simlab,loc,'.mat']);
    load([indir,'/velz',simlab,loc,'.mat']);
    load([indir,'/temp',simlab,loc,'.mat']);
    load([indir,'/dox2',simlab,loc,'.mat']);
    load([indir,'/dnit2',simlab,loc,'.mat']);
    load([indir,'/dox',simlab,loc,'.mat']);
end
[lt,lrho,lz]=size(velx);


%CREATE A SEQUENCE OF BINBARY OUTPUT FILES THAT CONTAIN A FRAME OF DATA EACH
system(['rm -rf ',outdir,'/*.dat'])
filename=[outdir,'simsize.dat']
fid=fopen(filename,'w');
fwrite(fid,lrho,'integer*4');
fwrite(fid,lz,'integer*4');
fclose(fid);


ymd=ymd0;
UTsec=UTsec0;
for it=1:lt
    velxnow=squeeze(velx(it,:,:));     %note that these are organized as t,rho,z - the fortran code wants z,rho
    velxnow=permute(velxnow,[2, 1]);

    velznow=squeeze(velz(it,:,:));
    velznow=permute(velznow,[2, 1]);

    tempnow=squeeze(temp(it,:,:));
    tempnow=permute(tempnow,[2, 1]);

    dox2snow=squeeze(dox2s(it,:,:));
    dox2snow=permute(dox2snow,[2, 1]);

    dnit2snow=squeeze(dnit2s(it,:,:));
    dnit2snow=permute(dnit2snow,[2, 1]);

    doxsnow=squeeze(doxs(it,:,:));
    doxsnow=permute(doxsnow,[2, 1]);

    filename=datelab(ymd,UTsec);
    filename=[outdir,filename,'.dat']
    fid=fopen(filename,'w');
    fwrite(fid,doxsnow,'real*8');
    fwrite(fid,dnit2snow,'real*8');
    fwrite(fid,dox2snow,'real*8');
    fwrite(fid,velxnow,'real*8');
    fwrite(fid,velznow,'real*8');
    fwrite(fid,tempnow,'real*8');
    fclose(fid);

    [ymd,UTsec]=dateinc(dtneu,ymd,UTsec);
end

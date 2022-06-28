function perturb_efield_bridge(cfg,xg)
%Electric field boundary conditions and initial condition for KHI case
arguments
  cfg (1,1) struct
  xg (1,1) struct
end

import stdlib.fileio.makedir

%% Sizes
x1=xg.x1(3:end-2);
x2=xg.x2(3:end-2);
x3=xg.x3(3:end-2);
lx1=xg.lx(1); lx2=xg.lx(2); lx3=xg.lx(3);

%% LOAD THE FRAME OF THE SIMULATION THAT WE WANT TO PERTURB
%dat = loadframe3Dcurvnoelec(cfg.indat_file);
time = datetime(2013,02,20) + seconds(28600);
dat = gemini3d.read.frame('~/simulations/KHI_archive/KHI_periodic_lowres_bridge/', "time", time);
lsp = size(dat.ns,4);


% %% SCALE EQ PROFILES UP TO SENSIBLE BACKGROUND CONDITIONS
% scalefact=2*2.75;
% nsscale=zeros(size(dat.ns));
% for isp=1:lsp-1
%     nsscale(:,:,:,isp) = scalefact * dat.ns(:,:,:,isp);
% end %for
% nsscale(:,:,:,lsp) = sum(nsscale(:,:,:,1:6),4);   %enforce quasineutrality


%% Apply the denisty perturbation as a jump and specified plasma drift variation (Earth-fixed frame)
% because this is derived from current density it is invariant with respect
% to frame of reference.
v0=-500;                             % background flow value, actually this will be turned into a shear in the Efield input file
densfact=3;                         % factor by which the density increases over the shear region - see Keskinen, et al (1988)
ell=1e3;                            % scale length for shear transition
%ell=6e3;
vn=-v0*(densfact+1)./(densfact-1);
B1val=-50000e-9;

nsperturb=zeros(size(dat.ns));
for isp=1:lsp
  for ix2=1:xg.lx(2)
%    amplitude=randn(xg.lx(1),1,xg.lx(3));    %AGWN, note this can make density go negative so error checking needed below
    amplitude=randn(1,1,xg.lx(3));
    amplitude=repmat(amplitude,[xg.lx(1),1,1]);
    amplitude=0.01*amplitude;
    nsperturb(:,ix2,:,isp)=dat.ns(:,ix2,:,isp)+amplitude.*dat.ns(:,ix2,:,isp);        %add some noise to seed instability
  end %for
end %for
nsperturb=max(nsperturb,1e4);                        %enforce a density floor (particularly need to pull out negative densities which can occur when noise is applied)
nsperturb(:,:,:,lsp)=sum(nsperturb(:,:,:,1:6),4);    %enforce quasineutrality


%% Remove any residual E-region from the simulation
x1ref=220e3;     %where to start tapering down the density in altitude
dx1=10e3;
taper=1/2+1/2*tanh((x1-x1ref)/dx1);
for isp=1:lsp-1
   for ix3=1:xg.lx(3)
       for ix2=1:xg.lx(2)
           nsperturb(:,ix2,ix3,isp)=1e6+nsperturb(:,ix2,ix3,isp).*taper;
       end %for
   end %for
end %for
inds=find(x1<150e3);
nsperturb(inds,:,:,:)=1e3;
nsperturb(:,:,:,lsp)=sum(nsperturb(:,:,:,1:6),4);    %enforce quasineutrality


%% Now compute an initial potential
vel3=zeros(lx2,lx3);
for ix3=1:lx3
    vel3(:,ix3)=v0*tanh(x2./ell)-vn;
end
vel3=flipud(vel3);
E2top=vel3*B1val;     % this is minus the electric field

% integrate field to get potential
DX2=diff(x2(:)',1);
DX2=[DX2,DX2(end)];
DX2=repmat(DX2(:),[1,lx3]);
Phitop=cumsum(E2top.*DX2,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
makedir(cfg.E0_dir);


%% CREATE ELECTRIC FIELD DATASET
E.llon=100;
E.llat=100;
% NOTE: cartesian-specific code
if lx2 == 1
  E.llon = 1;
elseif lx3 == 1
  E.llat = 1;
end
thetamin = min(xg.theta(:));
thetamax = max(xg.theta(:));
mlatmin = 90-thetamax*180/pi;
mlatmax = 90-thetamin*180/pi;
mlonmin = min(xg.phi(:))*180/pi;
mlonmax = max(xg.phi(:))*180/pi;

% add a 1% buff
latbuf = 1/100 * (mlatmax-mlatmin);
lonbuf = 1/100 * (mlonmax-mlonmin);
E.mlat = linspace(mlatmin-latbuf, mlatmax+latbuf, E.llat);
E.mlon = linspace(mlonmin-lonbuf, mlonmax+lonbuf, E.llon);
[E.MLON, E.MLAT] = ndgrid(E.mlon, E.mlat);
% mlonmean = mean(E.mlon);
% mlatmean = mean(E.mlat);


%% INTERPOLATE X2 COORDINATE ONTO PROPOSED MLON GRID
xgmlon=squeeze(xg.phi(1,:,1)*180/pi);
xgmlat=squeeze(90-xg.theta(1,1,:)*180/pi);
x2i=interp1(xgmlon,xg.x2(3:lx2+2),E.mlon,'linear','extrap');
x3i=interp1(xgmlat,xg.x3(3:lx3+2),E.mlat,'linear','extrap');


%% TIME VARIABLE (SECONDS FROM SIMULATION BEGINNING)
tmin = 0;
time = tmin:cfg.dtE0:cfg.tdur;
Nt = length(time);

%% SET UP TIME VARIABLES
UTsec = cfg.UTsec0 + time;     %time given in file is the seconds from beginning of hour
UThrs = UTsec / 3600;
E.expdate = cat(2, repmat(cfg.ymd(:)',[Nt, 1]), UThrs', zeros(Nt, 1), zeros(Nt, 1));
t = datenum(E.expdate);

%% CREATE DATA FOR BACKGROUND ELECTRIC FIELDS
if isfield(cfg, 'Exit')
  E.Exit = cfg.Exit * ones(E.llon, E.llat, Nt);
else
  E.Exit = zeros(E.llon, E.llat, Nt);
end
if isfield(cfg, 'Eyit')
  E.Eyit = cfg.Eyit * ones(E.llon, E.llat, Nt);
else
  E.Eyit = zeros(E.llon, E.llat, Nt);
end


%% CREATE DATA FOR BOUNDARY CONDITIONS FOR POTENTIAL SOLUTION
E.flagdirich=zeros(Nt,1);    %in principle can have different boundary types for different time steps...
E.Vminx1it = zeros(E.llon,E.llat, Nt);
E.Vmaxx1it = zeros(E.llon,E.llat, Nt);
%these are just slices
E.Vminx2ist = zeros(E.llat, Nt);
E.Vmaxx2ist = zeros(E.llat, Nt);
E.Vminx3ist = zeros(E.llon, Nt);
E.Vmaxx3ist = zeros(E.llon, Nt);

for it=1:Nt
    %ZEROS TOP CURRENT AND X3 BOUNDARIES DON'T MATTER SINCE PERIODIC



    %COMPUTE KHI DRIFT FROM APPLIED POTENTIAL
    vel3=zeros(E.llon, E.llat);
    for ilat=1:E.llat
        vel3(:,ilat)=v0*tanh(x2i./ell)-vn;
    end
    vel3=flipud(vel3);


    %CONVERT TO ELECTRIC FIELD (actually minus electric field...)
    E2slab=vel3*B1val;


    %INTEGRATE TO PRODUCE A POTENTIAL OVER GRID - then save the edge
    %boundary conditions
    DX2=diff(x2i(:)',1);
    DX2=[DX2,DX2(end)];
    DX2=repmat(DX2(:),[1,E.llat]);
    Phislab=cumsum(E2slab.*DX2,1);    %use a forward difference
    E.Vmaxx2ist(:,it)=squeeze(Phislab(E.llon,:));
    E.Vminx2ist(:,it)=squeeze(Phislab(1,:));
end

dat.ns = nsperturb;
dat.Phitop = Phitop;

%% Write initial plasma state out to a file
gemini3d.write.state(cfg.indat_file, dat);

%% Write electric field data to file
gemini3d.write.Efield(E, cfg.E0_dir, cfg.file_format)

end %function perturb_efield

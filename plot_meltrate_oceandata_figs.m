%% Plot remotely-sensed iceberg melt vs ocean observations



%% Initialize
clearvars;
addpath('/Users/ellynenderlin/Research/miscellaneous/general-code','/Users/ellynenderlin/Research/miscellaneous/general-code/cmocean');
addpath('/Users/ellynenderlin/Research/miscellaneous/general-code/AntarcticMappingTools');

%specify paths & file names for data
CTD_path = '/Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/CTD_Antarctica/';
CTD_data = [CTD_path,'Antarctic-ocean-data.mat'];
RACMO_path = '/Users/ellynenderlin/Research/miscellaneous/RACMO2.3_Antarctica/';
iceberg_path = '/Users/ellynenderlin/Research/NSF_Antarctic-Icebergs/iceberg-melt/';
figure_path = [iceberg_path,'figures/'];

%specify study site names
region = [{'Edgeworth-LarsenA'},{'Crane-LarsenB'},{'Ronne'},{'Filchner'},{'Amery'},{'Totten'},{'Mertz'},...
    {'Thwaites'},{'Ferrigno-Eltanin'},{'Seller-Bugge'},{'Heim-Marguerite'},{'Widdowson-Biscoe'},{'Cadman-Palmer'},{'Blanchard-Danco'},{'Leonardo-Danco'}];
leg_names = [{'Edgeworth'},{'Crane'},{'Ronne'},{'Filchner'},{'Polar Times'},{'Totten'},{'Mertz'},{'Thwaites'},{'Ferrigno'},{'Seller'},{'Heim'},{'Widdowson'},{'Cadman'},{'Blanchard'},{'Leonardo'}];
leg_ref = [9,10,11,12,13,14,15,8,7,6,5,4,3,2,1]; %arrange legend in alphabetical order

%specify plot params
marker = ['s','s','s','s','s','s','s','s','s','s','s','s','s','s','s']; %modify if you want to change symbols to indicate something about data (E vs W for example)
plot_letters = [{'i)'},{'j)'},{'k)'},{'l)'},{'m)'},{'n)'},{'o)'},{'h)'},{'g)'},{'f)'},{'e)'},{'d)'},{'c)'},{'b)'},{'a)'}]; %plot letters for sites to be used in geographically-arranged subplots
plot_loc = [2,4,6,8,10,12,14,15,13,11,9,7,5,3,1];
region_colors = [77,172,38; 77,172,38; 184,225,134; 184,225,134; 184,225,134; 184,225,134; 184,225,134;...
    241,182,218; 241,182,218; 208,28,139; 208,28,139; 208,28,139; 208,28,139; 208,28,139; 208,28,139]./255; 
Temp_cmap = cmocean('thermal',600); cmap_add = 3; cmap_mult = 100;
highmelt_cmap = cmocean('amp',100);
Tforcing_cmap = cmocean('amp',600);

%specify generic variables
rho_sw = 1026; %sea water density in kg m^-3
depth_cutoff = 800; %maximum depth of icebergs & therefore ocean observation data of interest in meters
years = [2011.75 2022.25]; year_ticks = [2013:2:2022]; %approximate date range for plots

%specify the buffer region to search for ocean data around the icebergs
buffer = 100000; %m

%load the RAMP image to plot as background for a map
cd /Users/ellynenderlin/Research/miscellaneous/RAMP
[A,S] = readgeoraster('Antarctic_RAMP_image_v2_1km.tif');
IM.x = S.XWorldLimits(1)+0.5*S.CellExtentInWorldX:S.CellExtentInWorldX:S.XWorldLimits(2)-0.5*S.CellExtentInWorldX;
IM.y = S.YWorldLimits(2)-0.5*S.CellExtentInWorldY:-S.CellExtentInWorldY:S.YWorldLimits(1)+0.5*S.CellExtentInWorldY;
IM.z=single(A);
clear A S;

%navigate to the iceberg directory as the default workspace
cd(iceberg_path);
close all;

%% Create profiles of ocean temperature & iceberg depth timeseries (Antarctic-iceberg-oceandata-profiles.eps)

%reload compiled data as needed
if ~exist('melt')
    load([iceberg_path,'Antarctic-icebergmelt-comparison.mat']);
end

%set up plot
close all; 
figure; set(gcf,'position',[50 50 800 1000]);
imagesc(IM.x,IM.y,IM.z); colormap gray; hold on; axis xy equal; colormap(gray(10001));

%loop through data
disp('Plotting temperature profiles & iceberg depth timeseries');
for i = 1:length(melt)
    if ~isempty(melt(i).oceant)
        subpl = subplot(8,2,plot_loc(i));
        
        %plot temperature profiles with colors to distinguish temps
        for j = 1:length(melt(i).oceantavg)
            prof_cmap = []; prof_d = [];
            
            if nanmedian(diff(melt(i).oceandavg_prof)) == 1
                %average over 20 rows to create smoothed profiles at 20 m increments
                for k = 11:20:size(melt(i).oceanTavg_prof(:,j),1)-10
                    prof_d = [prof_d; nanmean(melt(i).oceandavg_prof(k-10:k+10))];
                    if ~isnan(nanmean(melt(i).oceanTavg_prof(k-10:k+10,j))) %&& ~isnan(melt(i).oceanTfreeze_prof(k,j))
                        prof_cmap = [prof_cmap; Temp_cmap(round((nanmean(melt(i).oceanTavg_prof(k-10:k+10,j))+cmap_add)*cmap_mult),:)];
                        %                         plot(melt(i).oceantavg(j),nanmean(melt(i).oceandavg_prof(k-10:k+10)),'.','color',Temp_cmap(round((nanmean(melt(i).oceanTavg_prof(k-10:k+10,j))+3)*100),:),'markersize',10); hold on;
                    else
                        prof_cmap = [prof_cmap; 1,1,1];
                    end
                end
            else
                %plot at native standardized resolution because it should be ~20 m
                for k = 1:size(melt(i).oceanTavg_prof(:,j),1)
                    prof_d = [prof_d; melt(i).oceandavg_prof(k)];
                    if ~isnan(melt(i).oceanTavg_prof(k,j))
                        prof_cmap = [prof_cmap; Temp_cmap(round((melt(i).oceanTavg_prof(k,j)+cmap_add)*cmap_mult),:)];
                        %                         plot(melt(i).oceantavg(j),melt(i).oceandavg_prof(k),'.','color',Temp_cmap(round((melt(i).oceanTavg_prof(k,j)+3)*100),:),'markersize',10); hold on;
                    else
                        prof_cmap = [prof_cmap; 1,1,1];
                    end
                end
            end
            top_ref = find(sum(prof_cmap,2) < 3,1,'first'); %identify the deepest part of the profile with data as the addition of the plot colors < 3 (sum = 3 is white for NaNs)
            bottom_ref = find(sum(prof_cmap,2) < 3,1,'last'); %identify the deepest part of the profile with data as the addition of the plot colors < 3 (sum = 3 is white for NaNs)
            scatter(repmat(melt(i).oceantavg(j),size(prof_d(top_ref:bottom_ref))),prof_d(top_ref:bottom_ref),14,prof_cmap(top_ref:bottom_ref,:),'filled','s'); hold on;
            clear prof_cmap prof_d bottom_ref;
        end
        
        %plot the iceberg depths for each date
        plot(nanmean([melt(i).to melt(i).tf],2),melt(i).d,'.k'); hold on;
        errorbar(nanmean([melt(i).to melt(i).tf],2),melt(i).d,[],[],abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).to),abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).tf),'.k');
        
        %format plot
        set(gca,'ydir','reverse','xlim',years,'ylim',[0 depth_cutoff],'ytick',[0:250:750],'fontsize',16);
        if plot_loc(i) == 15
            xlabel('Year','fontsize',16); ylabel('Depth (m b.s.l.)','fontsize',16);
        end
        text(min(get(gca,'xlim'))+0.025*(max(get(gca,'xlim'))-min(get(gca,'xlim'))),max(get(gca,'ylim'))-0.2*abs(max(get(gca,'ylim'))-min(get(gca,'ylim'))),[char(plot_letters(i)),' ',char(melt(i).dispname)],'fontsize',16);
        drawnow;

    else
        subpl = subplot(8,2,plot_loc(i));
        %plot the iceberg depths for each date
        plot(nanmean([melt(i).to melt(i).tf],2),melt(i).d,'.k'); hold on;
        errorbar(nanmean([melt(i).to melt(i).tf],2),melt(i).d,[],[],abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).to),abs(nanmean([melt(i).to melt(i).tf],2)-melt(i).tf),'.k');
        
        %format plot
        set(gca,'ydir','reverse','xlim',years,'ylim',[0 depth_cutoff],'ytick',[0:250:750],'fontsize',16);
        text(min(get(gca,'xlim'))+0.025*(max(get(gca,'xlim'))-min(get(gca,'xlim'))),max(get(gca,'ylim'))-0.2*abs(max(get(gca,'ylim'))-min(get(gca,'ylim'))),[char(plot_letters(i)),' ',char(melt(i).dispname)],'fontsize',16);
        drawnow;
        
    end
    
    %format axes
    pos = get(gca,'position'); set(gca,'position',[pos(1) pos(2) 1.05*pos(3) 1.15*pos(4)]);
    if plot_loc(i) == 14
        set(gca,'xlim',years,'xtick',year_ticks,'ylim',[0 depth_cutoff],'ytick',[0:250:750],'fontsize',16);
        xlabel('Year','fontsize',16); 
    elseif plot_loc(i) == 15
        set(gca,'xlim',years,'xtick',year_ticks,'ylim',[0 depth_cutoff],'ytick',[0:250:750],'fontsize',16);
        xlabel('Year','fontsize',16); ylbl = ylabel('Depth (m b.s.l.)','fontsize',16);
        set(ylbl,'position',[min(years)-1.5 -3000 -1]);
    else
        set(gca,'xlim',years,'xtick',year_ticks,'xticklabel',[],'ylim',[0 depth_cutoff],'ytick',[0:250:750],'fontsize',16);
    end
    box on;
    
end
%add a colorbar
annotation('rectangle',[0.57 0.11 0.35 0.065],'facecolor','w','edgecolor','k');
for j = 1:length(Temp_cmap)
    annotation('line',[0.595+j/2000 0.595+j/2000],[0.1525 0.170],'color',Temp_cmap(j,:),'linewidth',1.5);
end
annotation('textbox',[0.57 0.135 0.05 0.02],'string',['-',num2str(cmap_add),char(176),'C'],'fontsize',16,'edgecolor','none');
annotation('textbox',[0.725 0.135 0.05 0.02],'string',['0',char(176),'C'],'fontsize',16,'edgecolor','none');
annotation('textbox',[0.875 0.135 0.05 0.02],'string',[num2str(cmap_add),char(176),'C'],'fontsize',16,'edgecolor','none');
annotation('textbox',[0.65 0.115 0.25 0.02],'string','ocean temperature','fontsize',16,'edgecolor','none');

%save
saveas(gcf,[figure_path,'Antarctic-iceberg-oceandata-profiles.eps'],'epsc'); saveas(gcf,[figure_path,'Antarctic-iceberg-oceandata-profiles.png'],'png');
disp('iceberg and ocean temp depth profiles saved');

% %create a map that shows the average temperature for each profile down to
% %~100 m depth (Xs) and the median iceberg depth for all sites
% figure(Tm_mapplot);
% for i = 1:length(melt)
%     if ~isempty(melt(i).oceant)
%         for j = 1:length(melt(i).oceantavg)
%             hundred_ref = find(melt(i).oceandavg_prof<=100,1,'last');
%             median_ref = find(melt(i).oceandavg_prof<=nanmedian(melt(i).d),1,'last');
%             if ~isnan(nanmean(melt(i).oceanTavg_prof(1:hundred_ref,j)-melt(i).oceanTfreeze_prof(1:hundred_ref,j)))
%             plot(melt(i).oceanxavg(j),melt(i).oceanyavg(j),'x','color',Temp_cmap(round((nanmean(melt(i).oceanTavg_prof(1:hundred_ref,j)-melt(i).oceanTfreeze_prof(1:hundred_ref,j))+1)*100),:)); hold on;
%             end
%         end
%     end
%     plot(nanmean(melt(i).x),nanmean(melt(i).y),[marker(i),'k'],'markerfacecolor',depth_cmap(round(nanmean(melt(i).d)),:),'markersize',12); hold on;
% end
% %add labels to the location plot
% for i = 1:length(melt)
%     figure(Tm_mapplot); 
%     if strcmp(marker(i),'d')
%         text(nanmean(melt(i).x)+100000,nanmean(melt(i).y),char(plot_letters(i)),'fontsize',16);
%     else
%         if strcmp(char(plot_letters(i)),'f)')
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)-100000,char(plot_letters(i)),'fontsize',16); 
%         elseif strcmp(char(plot_letters(i)),'a)')
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y)+100000,char(plot_letters(i)),'fontsize',16); 
%         else
%             text(nanmean(melt(i).x)-200000,nanmean(melt(i).y),char(plot_letters(i)),'fontsize',16); 
%         end
%     end
% end
% %label
% set(gca,'xlim',[-28e5 28e5],'xtick',[-24e5:8e5:24e5],'xticklabel',[-2400:800:2400],...
%     'ylim',[-24e5 24e5],'ytick',[-24e5:8e5:24e5],'yticklabel',[-2400:800:2400],'fontsize',24); grid off;
% xlabel('Easting (km)','fontsize',24); ylabel('Northing (km)','fontsize',24);
% graticuleps(-50:-5:-90,-180:30:180);
% text(0,6.5e5,'85^oS','fontsize',16); text(0,12.0e5,'80^oS','fontsize',16); text(0,17.5e5,'75^oS','fontsize',16); text(0,23.0e5,'70^oS','fontsize',16);
% text(-16.5e5,25.25e5,'-30^oE','fontsize',16); text(12.5e5,25.25e5,'30^oE','fontsize',16); 
% colormap(gca,gray(100001));
% saveas(gcf,'Antarctic-iceberg-oceandata-map.eps','epsc'); saveas(gcf,'Antarctic-iceberg-oceandata-map.png','png');
% %now zoom in on the peninsula and save again
% set(gca,'xlim',[-28e5 -20e5],'xtick',[-28e5:2e5:-20e5],'xticklabel',[-2800:200:-2000],...
%     'ylim',[7.5e5 17.5e5],'ytick',[8e5:2e5:16e5],'yticklabel',[800:200:1600],'fontsize',24);
% graticuleps(-50:-2:-90,-180:10:180);
% saveas(gcf,'AntarcticPeninsula-iceberg-oceandata-map.eps','epsc'); saveas(gcf,'AntarcticPeninsula-iceberg-oceandata-map.png','png');

%% Plot maps and scatterplots of melt rate and ocean thermal forcing
close all; drawnow;
disp('Solving for thermal forcing & plotting figures to show iceberg melt rates vs thermal forcing');

%reload compiled data as needed
if ~exist('melt')
    load([iceberg_path,'Antarctic-icebergmelt-comparison.mat']);
end

%set-up the scatterplot
Tm_scatterplot = figure; set(gcf,'position',[850 50 800 400]); 

%set-up the map figures for 4 regions with ocean data: Antarctic Peninsula,
%Thwaites, Mertz, Filchner
Tm_mapplot = figure; set(gcf,'position',[50 50 800 800]);
im_cmap = colormap(gray(10001)); im_cmap(1,:) = [1 1 1];
imagesc(IM.x,IM.y,IM.z); hold on; axis xy equal; colormap(gca,im_cmap);

%set up a colormap for iceberg draft
depth_cmap_top = cmocean('-topo',round(depth_cutoff/2)); 
depth_cmap_bottom = cmocean('-topo',round(depth_cutoff*1.5)); 
depth_cmap = [depth_cmap_top(1:floor(depth_cutoff/4),:); depth_cmap_bottom(ceil(depth_cutoff*0.75):end,:)];
clear depth_cmap_*;
%depth_cmap = cmocean('deep',depth_cutoff); 

tempref = [];
for i = 1:size(region,2)
    disp_names(i) = {strjoin([cellstr(plot_letters(i)),' ',cellstr(leg_names(i))])};
    landsats = dir([iceberg_path,char(region(i)),'/LC*PS.TIF']);
    sitex = []; sitey = []; %set up empty cells to insert ocean data coordinates (if data exist) & iceberg coordinates for adjusting site maps
    
    %map for study site
    Tmsitemap = figure; set(gcf,'position',[50 850 800 450]);
    %LANDSAT SITE-SPECIFIC MAP
%     [A,S] = readgeoraster([landsats(1).folder,'/',landsats(1).name]);
%     im.x = S.XWorldLimits(1):S.SampleSpacingInWorldX:S.XWorldLimits(2);
%     im.y = S.YWorldLimits(2):-S.SampleSpacingInWorldY:S.YWorldLimits(1);
%     im.z = double(A); clear A S landsats;
%     imagesc(im.x,im.y,im.z); 
    %LIMA MOSAIC
    imagesc(IM.x,IM.y,IM.z);
    axis xy equal; colormap(gray(10001)); hold on;
    
    %identify the maximum iceberg draft
    for k = 1:length(melt(i).x)
        draft_map(k,:) = depth_cmap(round(nanmean(melt(i).d(k))),:);
        symbol_color(k) = ceil(2*(nanmedian(melt(i).m(k))*365)); 
        if symbol_color(k) > length(highmelt_cmap); symbol_color(k) = length(highmelt_cmap); end
    end
    max_ind = find(melt(i).d == max(melt(i).d)); %identify the deepest iceberg
    
    %find appropriate ocean data & extract thermal forcing estimates
    if ~isempty(melt(i).oceant)
        TFcoords = []; TF = [];
        
        %loop through remotely-sensed data and extract ocean forcing information for each iceberg
        for j = 1:length(melt(i).to) %length of melt(i).to corresponds to the number of icebergs
            %identify the time span of remotely-sensed iceberg melt rate estimates
            %(bi-annual=2, annual=1, or seasonal=0)
            if melt(i).tf(j)-melt(i).to(j) >= 2
                timespan = 2;
            elseif melt(i).tf(j)-melt(i).to(j) >= 1
                timespan = 1;
            else
                timespan = 0;
            end
            
            %if seasonal, find ocean data from approximately the same season
            %minrefs specifies the indices for the closest date (there may be multiple profiles) & oceantemps and oceansals are the corresponding profiles
            if size(melt(i).oceanx,2) ~=1; melt(i).oceanx = melt(i).oceanx'; melt(i).oceany = melt(i).oceany'; end %make sure coordinates are always a column vector
            if timespan == 0
                deciseas = nanmean([melt(i).to(j) melt(i).tf(j)]-floor(melt(i).to(j)),2); if deciseas > 1; deciseas = deciseas - floor(deciseas); end
                
                [mindiff,minref] = min(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas));
                if melt(i).oceant(minref)-floor(melt(i).oceant(minref)) >= melt(i).to(j)-floor(melt(i).to(j)) && melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).to(j)) %if to and tf are in the same year & minref is in between, find all between
                    minrefs = find(melt(i).oceant-floor(melt(i).oceant(minref)) >= melt(i).to(j)-floor(melt(i).to(j)) & melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).to(j)));
                elseif melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).to(j)-floor(melt(i).to(j)) && melt(i).oceant(minref)-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).tf(j)) %if tf is in a different year than to & minref is in between, find all between
                    minrefs = find(melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).to(j)-floor(melt(i).to(j)) & melt(i).oceant-floor(melt(i).oceant(minref)) <= melt(i).tf(j)-floor(melt(i).tf(j)));
                else
                    if mindiff < 0.5 %if there are no data that fall within the seasonal range of to and tf, find data within +/-3 months of the central day of year
                        minrefs = find(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas) <= 4/12);
                    else
                        minrefs = find(abs((melt(i).oceant-floor(melt(i).oceant))-deciseas) <= mindiff + 1/12);
                    end
                end
                oceanx = melt(i).oceanx(minrefs); oceany = melt(i).oceany(minrefs);
                oceantemps = melt(i).oceanT(:,minrefs); oceansals = melt(i).oceanS(:,minrefs); oceandepths = melt(i).oceand(:,minrefs);
                clear minref deciseas mindiff;
            else
                %if annual or bi-annual, find the closest year of ocean data
                [~,minref] = min(abs(melt(i).oceant-nanmean([melt(i).to(j) melt(i).tf(j)])));
                if melt(i).oceant(minref)-nanmean([melt(i).to(j) melt(i).tf(j)]) > 0
                    minrefs = find(melt(i).oceant>=melt(i).oceant(minref) & melt(i).oceant<=melt(i).oceant(minref)+timespan);
                else
                    minrefs = find(melt(i).oceant<=melt(i).oceant(minref) & melt(i).oceant>=melt(i).oceant(minref)-timespan);
                end

                oceanx = melt(i).oceanx(minrefs); oceany = melt(i).oceany(minrefs);
                oceantemps = melt(i).oceanT(:,minrefs); oceansals = melt(i).oceanS(:,minrefs); oceandepths = melt(i).oceand(:,minrefs);
                clear minref;
                
            end
            
            %extract temperature metrics over the iceberg draft
            for k = 1:length(minrefs)
                %identify the bottom of each profile
                if ~isempty(find(oceandepths(:,k)<=melt(i).d(j),1,'last'))
                    bottomrefs(k) = find(oceandepths(:,k)<=melt(i).d(j),1,'last'); %index for the deepest observation for each profile
                    bottomT(k) = melt(i).oceanT(bottomrefs(k),minrefs(k)); bottomS(k) = melt(i).oceanS(bottomrefs(k),minrefs(k));
                else
                    bottomrefs(k) = NaN; bottomT(k) = NaN; bottomS(k) = NaN;
                end
                
                %use the trapz function to calculate the mean for each profile
                %if its maximum observation depth is >90% of the iceberg draft
                if 0.9*max(oceandepths(~isnan(oceantemps(:,k)),k)) > melt(i).d(j) & min(oceandepths(~isnan(oceantemps(:,k)),k)) < 50
                    Tavg(k) = vertmean2(-oceandepths(:,k),oceantemps(:,k),-melt(i).d(j));
                else
                    Tavg(k) = NaN;
                end
                %repeat averaging but for salinity (may not have salinity corresponding to all temp observations)
                if 0.9*max(oceandepths(~isnan(oceansals(:,k)),k)) > melt(i).d(j) & min(oceandepths(~isnan(oceansals(:,k)),k)) < 50
                    Savg(k) = vertmean2(-oceandepths(:,k),oceansals(:,k),-melt(i).d(j));
                else
                    Savg(k) = NaN;
                end
                %repeat averaging, but to calculate the average freezing temperature of sea water (Tfp = -5.73*10^-2 (C/psu)*salinity + 8.32*10^-2 (C) - 7.61*10^-4 (C/dbar)*pressure)
                %pressure is approximately equivalent to depth
                if 0.9*max(oceandepths(~isnan(oceansals(:,k)),k)) > melt(i).d(j) & min(oceandepths(~isnan(oceansals(:,k)),k)) < 50
                    Tfpavg(k) = vertmean2(-oceandepths(:,k),(((-5.73*10^-2).*oceansals(:,k)) + (8.32*10^-2) - ((7.61*10^-4).*oceandepths(:,k))),-melt(i).d(j));
                else
                    Tfpavg(k) = NaN;
                end
            end

            
            %set the size of the melt rate vs thermal forcing scatterplot
            %symbols so that they vary with draft
            draft_size(j) = round(melt(i).d(j)/5)+20;
            
            %compile thermal forcing data to plot only one thermal forcing 
            %estimate for all icebergs that use the same profile
            TFcoords = [TFcoords; oceanx oceany]; TF = [TF; (Tavg - Tfpavg)'];
            
            clear minrefs oceantemps oceansals oceandepths oceanx oceany timespan Tavg Tfpavg Savg;
        end
        
        %plot the median thermal forcing from each profile on the overview map
        figure(Tm_mapplot);
        %MEDIAN OF AVERAGE THERMAL FORCING FOR ALL ICEBERGS
        %         %calculate the median thermal forcing for each profile
        %         [unique_coords,unique_refs,inds] = unique(TFcoords,'rows');
        %         for j = 1:max(unique_refs)
        %             %median of thermal forcing
        %             TFmedian(j) = nanmedian(TF(inds==j));
        %             
        %             %create the colormap to show thermal forcing on the map
        %             if ~isnan(TFmedian(j))
        %                 tempref = round(TFmedian(j)*(2*cmap_mult));
        %                 if tempref < 1
        %                     temp_map(j,:) = [0 0 0];
        %                 else
        %                     temp_map(j,:) = Tforcing_cmap(tempref,:);
        %                 end
        %                 clear tempref;
        %             else
        %                 temp_map(j,:) = [1 1 1];
        %             end
        %         end
        %         sitex = [sitex; unique_coords(sum(temp_map,2)~=3,1)]; sitey = [sitey; unique_coords(sum(temp_map,2)~=3,2)]; 
        %         scatter(unique_coords(sum(temp_map,2)~=3,1),unique_coords(sum(temp_map,2)~=3,2),16,temp_map((sum(temp_map,2)~=3),:),'filled','o'); hold on;
        %MEDIAN THERMAL FORCING OVER MAXIMUM ICEBERG DRAFT
        for k = 1:size(melt(i).oceanT,2)
            %calculate the average temperature for the profile
            if 0.9*max(melt(i).oceand(~isnan(melt(i).oceanT(:,k)),k)) > melt(i).d(max_ind) & min(melt(i).oceand(~isnan(melt(i).oceanT(:,k)),k)) < 50
                Tavg(k) = vertmean2(-melt(i).oceand(:,k),melt(i).oceanT(:,k),-melt(i).d(max_ind));
            else
                Tavg(k) = NaN;
            end
            %calculate the average freezing temperature for the profile
            if 0.9*max(melt(i).oceand(~isnan(melt(i).oceanS(:,k)),k)) > melt(i).d(max_ind) & min(melt(i).oceand(~isnan(melt(i).oceanS(:,k)),k)) < 50
                Tfpavg(k) = vertmean2(-melt(i).oceand(:,k),(((-5.73*10^-2).*melt(i).oceanS(:,k)) + (8.32*10^-2) - ((7.61*10^-4).*melt(i).oceand(:,k))),-melt(i).d(max_ind));
            else
                Tfpavg(k) = NaN;
            end
            Tfavg(k) = Tavg(k) - Tfpavg(k); %thermal forcing
            
            %assign to a color for scatterplot
            if ~isnan(Tfavg(k))
%                 tempref = round(Tfavg(k)*(2*cmap_mult)); %temp index if using Tforcing_cmap
                tempref = round((Tavg(k)+cmap_add)*cmap_mult); %temp index if using Temp_cmap
                if tempref < 1
                    temp_map(k,:) = [0 0 0];
                else
%                     temp_map(k,:) = Tforcing_cmap(tempref,:);
                    temp_map(k,:) = Temp_cmap(tempref,:);
                end
                clear tempref;
            else
                temp_map(k,:) = [1 1 1];
            end
        end
        scatter(melt(i).oceanx(sum(temp_map,2)~=3),melt(i).oceany(sum(temp_map,2)~=3),16,temp_map((sum(temp_map,2)~=3),:),'filled','o'); hold on;
        clear Tavg Tfpavg Tfavg;
        
        %plot the median thermal forcing from each profile on the site map
        figure(Tmsitemap);
%         scatter(unique_coords(sum(temp_map,2)~=3,1),unique_coords(sum(temp_map,2)~=3,2),16,temp_map((sum(temp_map,2)~=3),:),'filled','o'); hold on; %median of all profiles
        scatter(melt(i).oceanx(sum(temp_map,2)~=3),melt(i).oceany(sum(temp_map,2)~=3),16,temp_map((sum(temp_map,2)~=3),:),'filled','o'); hold on; %over maximum draft only
        sitex = [sitex; melt(i).oceanx(sum(temp_map,2)~=3)]; sitey = [sitey; melt(i).oceany(sum(temp_map,2)~=3)]; 
        clear temp_map;
        
        
        %create an individual plot of temp vs meltrate for the study site
        site_scatter = figure; set(gcf,'position',[850 650 800 400]);
        scatter(melt(i).oceanTavg-melt(i).oceanTfp,100*melt(i).m,2*draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        set(gca,'fontsize',16); grid on;
        xlabel(['Thermal forcing (',char(176),'C above freezing)'],'fontsize',16); ylabel('Melt rate (cm/d)','fontsize',16);
        title(melt(i).dispname); drawnow;
        [f,gof] = fit(melt(i).oceanTavg-melt(i).oceanTfp,melt(i).m,'poly1'); %disp(['Trendline r^2 = ',num2str(gof.rsquare)]);
        if gof.rsquare > 0.5
            saveas(gcf,[figure_path,char(melt(i).name),'-iceberg-oceandata-scatterplot.eps'],'epsc'); saveas(gcf,[figure_path,char(melt(i).name),'-iceberg-oceandata-scatterplot.png'],'png');
        end
        close(site_scatter);
        
        %add temp vs meltrate data to composite scatterplot
        figure(Tm_scatterplot);
        if ~isempty(strmatch('Edgeworth',char(leg_names(i)))) %only create a handle for one study site from each region (EAP,EAIS,WAIS,WAP)
            sp(1) = scatter(melt(i).oceanTavg-melt(i).oceanTfp,365*melt(i).m,draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        elseif ~isempty(strmatch('Mertz',char(leg_names(i))))
            sp(2) = scatter(melt(i).oceanTavg-melt(i).oceanTfp,365*melt(i).m,draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        elseif ~isempty(strmatch('Thwaites',char(leg_names(i))))
            sp(3) = scatter(melt(i).oceanTavg-melt(i).oceanTfp,365*melt(i).m,draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        elseif ~isempty(strmatch('Cadman',char(leg_names(i))))
            sp(4) = scatter(melt(i).oceanTavg-melt(i).oceanTfp,365*melt(i).m,draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        else
            scatter(melt(i).oceanTavg-melt(i).oceanTfp,365*melt(i).m,draft_size,region_colors(i,:),'filled','s','markeredgecolor','k'); hold on;
        end
        %         for j = 1:length(melt(i).to)
        %             plot(melt(i).oceanTavg(j)-melt(i).oceanTfp(j,1),365*melt(i).m(j),[marker(i),'k'],'markerfacecolor',depth_cmap(round(melt(i).d(j)),:),'markersize',12); hold on;
        %         end
        
        clear draft_size;
    end
    
    %add data to the overview map
    figure(Tm_mapplot);
    mp(i) = scatter(melt(i).x(max_ind),melt(i).y(max_ind),round(melt(i).d(max_ind)/5)+10,highmelt_cmap(symbol_color(max_ind),:),'filled','s','markeredgecolor','k','linewidth',0.5); hold on; %only plot a symbol for the deepest-drafted iceberg
    clear temp_map;
    
    %add iceberg locations to the site map
    figure(Tmsitemap);
    scatter(melt(i).x,melt(i).y,round(melt(i).d/5)+20,highmelt_cmap(symbol_color,:),'filled','s','markeredgecolor','k','linewidth',0.5); hold on;
%     scatter(melt(i).x,melt(i).y,48,draft_map,'filled','s','markeredgecolor','k','linewidth',0.5); hold on;
    clear draft_map symbol_color;
    
    %format the site map & save
    figure(Tmsitemap);
    sitex = [sitex; melt(i).x]; sitey = [sitey; melt(i).y];
    %SCALE SITE PLOTS TO DATA EXTENT
    %     if sqrt((max(sitex)-min(sitex)).^2 + (max(sitey)-min(sitey)).^2)+10000 < 50000
    %         set(gca,'xlim',[min(sitex)-5000 max(sitex)+5000],'ylim',[min(sitey)-5000 max(sitey)+5000],...
    %             'xtick',[(ceil(min(sitex)/1000)*1000-5000):5000:(floor(max(sitex)/1000)*1000+5000)],...
    %             'xticklabel',[(ceil(min(sitex)/1000)-5):5:(floor(max(sitex)/1000)+5)],...
    %             'ytick',[(ceil(min(sitey)/1000)*1000-5000):5000:(floor(max(sitey)/1000)*1000+5000)],...
    %             'yticklabel',[(ceil(min(sitey)/1000)-5):5:(floor(max(sitey)/1000)+5)],...
    %             'fontsize',16);
    %     else
    %         set(gca,'xlim',[min(sitex)-5000 max(sitex)+5000],'ylim',[min(sitey)-5000 max(sitey)+5000],...
    %             'xtick',[(ceil(min(sitex)/1000)*1000-5000):10000:(floor(max(sitex)/1000)*1000+5000)],...
    %             'xticklabel',[(ceil(min(sitex)/1000)-5):10:(floor(max(sitex)/1000)+5)],...
    %             'ytick',[(ceil(min(sitey)/1000)*1000-5000):5000:(floor(max(sitey)/1000)*1000+5000)],...
    %             'yticklabel',[(ceil(min(sitey)/1000)-5):5:(floor(max(sitey)/1000)+5)],...
    %             'fontsize',16);
    %     end
    %GENERIC SITE SCALING BASED ON BUFFER FOR OCEAN DATA SEARCH
    set(gca,'xlim',[nanmean(melt(i).x)-buffer nanmean(melt(i).x)+buffer],'ylim',[nanmean(melt(i).y)-buffer nanmean(melt(i).y)+buffer],...
        'xtick',[(ceil((nanmean(melt(i).x)-buffer)/1000)*1000-5000):20000:(floor((nanmean(melt(i).x)+buffer)/1000)*1000+5000)],...
        'xticklabel',[(ceil((nanmean(melt(i).x)-buffer)/1000)-5):20:(floor((nanmean(melt(i).x)+buffer)/1000)+5)],...
        'ytick',[(ceil((nanmean(melt(i).y)-buffer)/1000)*1000-5000):20000:(floor((nanmean(melt(i).y)+buffer)/1000)*1000+5000)],...
        'yticklabel',[(ceil((nanmean(melt(i).y)-buffer)/1000)-5):20:(floor((nanmean(melt(i).y)+buffer)/1000)+5)],...
        'XTickLabelRotation',45,'fontsize',16); grid on;
    
    %finish formatting the plot
    xlabel('Easting (km)','fontsize',16); ylabel('Northing (km)','fontsize',16);
    %resize vertical dimension to maximize figure window usage
    xlims = get(gca,'xlim'); ylims = get(gca,'ylim'); figpos = get(gcf,'position');
    set(gcf,'position',[figpos(1) figpos(2) figpos(3) (max(ylims)-min(ylims))/(max(xlims)-min(xlims))*figpos(3)]);
    clear im;
    saveas(Tmsitemap,[figure_path,char(region(i)),'_iceberg-oceandata-map.eps'],'epsc'); saveas(Tmsitemap,[figure_path,char(region(i)),'_iceberg-oceandata-map.png'],'png');
    clear xlims ylims; close(Tmsitemap);
end

%format the overview map & save
figure(Tm_mapplot);
%add labels
for i = 1:length(melt)
    if strcmp(char(plot_letters(i)),'f)')
        text(nanmean(melt(i).x)-100000,nanmean(melt(i).y)-100000,char(plot_letters(i)),'fontsize',12);
    elseif strcmp(char(plot_letters(i)),'a)')
        text(nanmean(melt(i).x)-100000,nanmean(melt(i).y)+75000,char(plot_letters(i)),'fontsize',12);
    elseif strcmp(char(plot_letters(i)),'b)') || strcmp(char(plot_letters(i)),'c)') || strcmp(char(plot_letters(i)),'e)')
        text(nanmean(melt(i).x)-100000,nanmean(melt(i).y)-50000,char(plot_letters(i)),'fontsize',12);
    else
        text(nanmean(melt(i).x)+75000,nanmean(melt(i).y),char(plot_letters(i)),'fontsize',12);
    end
end
%label axes of map
set(gca,'xlim',[-28e5 28e5],'xtick',[-32e5:8e5:32e5],'xticklabel',[-3200:800:3200],...
    'ylim',[-24e5 24e5],'ytick',[-24e5:8e5:24e5],'yticklabel',[-2400:800:2400],'fontsize',16); grid off;
xlabel('Easting (km)','fontsize',16); ylabel('Northing (km)','fontsize',16);
%add polar stereo coordinates
graticuleps(-50:-5:-90,-180:30:180);
text(0,6.5e5,'85^oS','fontsize',16); text(0,12.0e5,'80^oS','fontsize',16); text(0,17.5e5,'75^oS','fontsize',16); text(0,23.0e5,'70^oS','fontsize',16);
text(-16.5e5,25.25e5,'-30^oE','fontsize',16); text(12.5e5,25.25e5,'30^oE','fontsize',16); 
rectangle('position',[-26.5e5 -23.5e5 28e5 15e5],'facecolor','w','edgecolor','k'); xlims = get(gca,'xlim'); ylims = get(gca,'ylim');

%add color & size legends for iceberg data
%sizes
scatter(min(xlims)+0.4*(max(xlims)-min(xlims)),min(ylims)+0.07*(max(ylims)-min(ylims)),round(100/5+10),'w','filled','s','markeredgecolor','k'); text(min(xlims)+0.425*(max(xlims)-min(xlims)),min(ylims)+0.07*(max(ylims)-min(ylims)),'100 m','fontsize',16); %scaling y-offset = 0.16*(max(ylims)-min(ylims))
scatter(min(xlims)+0.4*(max(xlims)-min(xlims)),min(ylims)+0.15*(max(ylims)-min(ylims)),round(300/5+10),'w','filled','s','markeredgecolor','k'); text(min(xlims)+0.425*(max(xlims)-min(xlims)),min(ylims)+0.15*(max(ylims)-min(ylims)),'300 m','fontsize',16); %scaling y-offset = 0.11*(max(ylims)-min(ylims))
scatter(min(xlims)+0.4*(max(xlims)-min(xlims)),min(ylims)+0.23*(max(ylims)-min(ylims)),round(500/5+10),'w','filled','s','markeredgecolor','k'); text(min(xlims)+0.425*(max(xlims)-min(xlims)),min(ylims)+0.23*(max(ylims)-min(ylims)),'500 m','fontsize',16); %scaling y-offset = 0.05*(max(ylims)-min(ylims))
text(min(xlims)+0.40*(max(xlims)-min(xlims)),min(ylims)+0.305*(max(ylims)-min(ylims)),'iceberg','fontsize',16,'fontweight','bold');
text(min(xlims)+0.415*(max(xlims)-min(xlims)),min(ylims)+0.275*(max(ylims)-min(ylims)),'draft','fontsize',16,'fontweight','bold');
%colors
for k = 1:length(highmelt_cmap)
    plot([min(xlims)+0.20*(max(xlims)-min(xlims)) min(xlims)+0.25*(max(xlims)-min(xlims))],...
        [min(ylims)+0.245*(max(ylims)-min(ylims))-k*((0.20*(max(ylims)-min(ylims)))/length(highmelt_cmap)) min(ylims)+0.245*(max(ylims)-min(ylims))-k*((0.20*(max(ylims)-min(ylims)))/length(highmelt_cmap))],...
        '-','linewidth',2*((max(ylims)-min(ylims))/(max(xlims)-min(xlims))),'color',highmelt_cmap(k,:));
end
text(min(xlims)+0.26*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims)),'<1 m yr^{-1}','fontsize',16);
text(min(xlims)+0.26*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims))-(length(highmelt_cmap)/5)*((0.20*(max(ylims)-min(ylims)))/length(highmelt_cmap)),'10 m yr^{-1}','fontsize',16);
text(min(xlims)+0.26*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims))-length(highmelt_cmap)*((0.20*(max(ylims)-min(ylims)))/length(highmelt_cmap)),'50 m yr^{-1}','fontsize',16);
text(min(xlims)+0.23*(max(xlims)-min(xlims)),min(ylims)+0.305*(max(ylims)-min(ylims)),'iceberg','fontsize',16,'fontweight','bold');
text(min(xlims)+0.22*(max(xlims)-min(xlims)),min(ylims)+0.275*(max(ylims)-min(ylims)),'melt rate','fontsize',16,'fontweight','bold');

% %add color legend for depth
% rectangle('position',[-26.05e5 -22.8e5 2.1e5 length(depth_cmap)*1000+0.1e5],'facecolor','k','edgecolor','k');
% for k = 1:length(depth_cmap)
%     plot([-26e5 -24e5],[-22.75e5+k*1000 -22.75e5+k*1000],'-','color',depth_cmap(end-(k-1),:)); hold on;
% end
% text(-23.25e5,-22.75e5+k*1000,'0 m','fontsize',16); 
% text(-23.25e5,-22.75e5+(k-200)*1000,'200 m','fontsize',16); 
% text(-23.25e5,-22.75e5+(k-800)*1000,'800 m','fontsize',16);

% %add color legend for thermal forcing
% rectangle('position',[-17.30e5 -22.8e5 2.1e5 length(Tforcing_cmap)*1000+0.1e5],'facecolor','k','edgecolor','k');
% for k = 1:length(Tforcing_cmap)
%     plot([-17.25e5 -15.25e5],[-22.75e5+k*1000 -22.75e5+k*1000],'-','color',Tforcing_cmap(k,:)); hold on;
% end
% text(-14.5e5,-22.75e5+k*1000,[num2str((length(Tforcing_cmap)/(2*cmap_mult))),char(176),'C'],'fontsize',16); 
% text(-14.5e5,-22.75e5+(length(Tforcing_cmap)/2)*1000,[num2str((length(Tforcing_cmap)/(2*cmap_mult))/2),char(176),'C'],'fontsize',16); 
% text(-14.5e5,-22.75e5,[num2str(0),char(176),'C'],'fontsize',16);
%add color legend for ocean temperature
% rectangle('position',[-17.30e5 -22.8e5 2.1e5 length(Temp_cmap)*1000+0.1e5],'facecolor','k','edgecolor','k');
for k = 1:length(Temp_cmap)
    plot([min(xlims)+0.06*(max(xlims)-min(xlims)) min(xlims)+0.11*(max(xlims)-min(xlims))],...
        [min(ylims)+0.245*(max(ylims)-min(ylims))-k*((0.20*(max(ylims)-min(ylims)))/length(Temp_cmap)) min(ylims)+0.245*(max(ylims)-min(ylims))-k*((0.20*(max(ylims)-min(ylims)))/length(Temp_cmap))],...
        '-','color',Temp_cmap(k,:)); hold on;
end
text(min(xlims)+0.12*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims)),['-',num2str(cmap_add),char(176),'C'],'fontsize',16); 
text(min(xlims)+0.12*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims))-(length(Temp_cmap)/2)*((0.20*(max(ylims)-min(ylims)))/length(Temp_cmap)),['0',char(176),'C'],'fontsize',16); 
text(min(xlims)+0.12*(max(xlims)-min(xlims)),min(ylims)+0.245*(max(ylims)-min(ylims))-(length(Temp_cmap))*((0.20*(max(ylims)-min(ylims)))/length(Temp_cmap)),[num2str(cmap_add),char(176),'C'],'fontsize',16);
text(min(xlims)+0.07*(max(xlims)-min(xlims)),min(ylims)+0.305*(max(ylims)-min(ylims)),'ocean','fontsize',16,'fontweight','bold');
text(min(xlims)+0.075*(max(xlims)-min(xlims)),min(ylims)+0.275*(max(ylims)-min(ylims)),'temp.','fontsize',16,'fontweight','bold');

%save figure
[sorted,inds] = sort(leg_ref); mp_sort = mp(inds);
colormap(gca,im_cmap);%make sure the image colormap didn't get accidentally altered
legmap = legend(mp_sort,[char(disp_names(inds))]); set(legmap,'location','northoutside','fontsize',16,'NumColumns',5); 
legmappos = get(legmap,'position'); set(legmap,'position',[0.05 legmappos(2)+0.05 legmappos(3) legmappos(4)]);
gcapos = get(gca,'position'); set(gca,'position',[gcapos(1) 0.09 gcapos(3) gcapos(4)]);
saveas(Tm_mapplot,[figure_path,'Antarctic-iceberg-oceandata-map.eps'],'epsc'); saveas(Tm_mapplot,[figure_path,'Antarctic-iceberg-oceandata-map.png'],'png');


%label the scatterplot & save
figure(Tm_scatterplot);  
set(gca,'fontsize',16); grid on;
%uncomment next 4 lines if you use the plot function to specify symbol colors as a function of draft
% for k = 1:length(depth_cmap)
%     plot([0.1 0.25],[47.5-(k/100) 47.5-(k/100)],'-','color',depth_cmap(k,:)); hold on;
% end
% text(0.275,47,'0 m','fontsize',16); text(0.275,45,'200 m','fontsize',16); text(0.275,39.5,'750 m','fontsize',16);
%next 9 lines should be used if scatterplot function specifies symbol colors as a function of region & symbol size as a function of draft
ylims = get(gca,'ylim');
rectangle('position',[0.425 max(ylims) - 0.06*((depth_cutoff-50)/150*1.15)*(range(ylims)) 0.3 0.06*((depth_cutoff-50)/150*1.05)*(range(ylims))],'facecolor','w','edgecolor','k');
for j = 1:1:(depth_cutoff-50)/150
    draft_size(j) = round((50+((j-1)*150))/8)+12;
    yloc(j) = max(ylims) - 0.06*j*(range(ylims)) - 0.01*(range(ylims));
    text(0.525,yloc(j),[num2str((50+((j-1)*150))),' m'],'fontsize',16);
end
scatter(repmat(0.475,size(yloc)),yloc,draft_size,'w','filled','s','markeredgecolor','k'); hold on;
sp_leg = legend(sp,'EAP','EAIS','WAIS','WAP'); set(sp_leg,'location','northwest');
xlabel(['Thermal forcing (',char(176),'C above freezing)'],'fontsize',16); ylabel('Melt rate (m/yr)','fontsize',16);
saveas(Tm_scatterplot,[figure_path,'Antarctic-iceberg-meltrate-temp-depth-scatterplots.eps'],'epsc'); saveas(Tm_scatterplot,[figure_path,'Antarctic-iceberg-meltrate-temp-depth-scatterplots.png'],'png');
clear ylims yloc draft_size;


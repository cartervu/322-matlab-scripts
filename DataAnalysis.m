% 322 Data analysis Script

% To be confirmed: 
% 1) is wf_increment in seconds? The frequency is roughly 2 Hz?
% 2) which data came from which probe? Which column is bottom, middle, top?
% 3) How should I color the plots? Should each run be the same color, or
% each sensor be the same color? I think sensor makes more sense, since the
% time to equilibrium will run longer for any given one, and will be
% clearly distinguishable, but perhaps we don't need to given that the
% bolding makes things clearer
% 4) Should we include uncertainty on the measurements? Is this something
% we will plot? 
% -- yes, we should include uncertainty on the measurements, I just really
% don't want to do it lol
% shouldn't actually be all that bad tho
% 5) comments from the interim report
% 6) Color the standard deviations the same (so +-1 sigma is the same,
% +-2sigma is the same)

%% Extract data from .xlsx, read into cell array
% Python equivalent: pandas df

% 7 trials, so 14 total xlsx files with 4 T columns each
% I also want the t vector, but I should introduce that after I tare the
% data
clear all; close all; clc;

DataPath = '/Users/carter/Software/matlab/322_Matlab_Scripts/Data';
FigPath = '/Users/carter/Software/matlab/322_Matlab_Scripts/Figures';
cd(DataPath)

DataCell = cell(2,7);
InfoSheets = cell(2,7);
datainfo = dir;
for i = 1:14
    name = datainfo(i+2).name;
    sheet_name=sheetnames(name);
%     detectImportOptions(name)
    DataCell{i} = xlsread(name,'Untitled');
    InfoSheets{i} = xlsread(name,sheet_name(1));
end

% NEVER ASSIGN TO DataCell EVER AGAIN -- Don't want to have to read in data
% again, annoying.

%% Task list
% 1: tare out the data so they start at the same time, and cut it off after
% the system equilibriates.
% 2: +-1,2sigma bound on average T(t), plot (7 plots), plot all the central
% averages, maybe a sigma bound together (1 plot)
% 3: average qdot(t), sigma bounds, plots
% 4: average rate of boil-off mdot, sigma bounds, plots
% 5: parameter estimation for h, other variables


%% Check min temp of each run
clc;
minvals = [];
maxvals = [];

for i = 1:14
    for probe = 1:4
        minvals(i,probe) = min(DataCell{i}(:,probe));
        maxvals(i,probe) = max(DataCell{i}(:,probe));
    end
end
max(max(minvals))

%% Task 1: Initial Data Processing, part of task 2, computing sigma bounds
% clear all; close all; clc;
close all; clc;
cd(FigPath)

TCell = cell(9,7);
dt = 0.510204075;
% Note: T0 ~ 22.6517 deg C
eqbT = -194 % deg C, this is an approximation. Would be better to get the long-run equilibrium temp of each run, and use that,
% but this is good enough, within 2 degrees for sure.



% Task 1: make it so they all start at the same time, end after experiment reaches equilibrium.

% Task 2: averages and +-sigma bounds

SizeNames = ["1-38","1-50","1-63","1-75","1-88","2-00","Control"];
for i = 0:6
    index = 2*i+1; % = [1, 3, 5, 7, 9]
    TMat1 = DataCell{index}; % load run 1
    TMat2 = DataCell{index+1}; % load run 2
%     disp(size(TMat2))
    tvec1 = 0:dt:dt*(length(TMat1(:,1))-1); % time vec run 1
    tvec2 = 0:dt:dt*(length(TMat2(:,1))-1); % time vec run 2
    figure() % create new figure for each column of DataCell
    
    % Get experiment start and end times, cut/moidfy temperature, time 
    % vectors appropriately:
    start1 = [];
    end1 = [];
    start2 = [];
    end2 = [];
    for probe = 1:4
        start1(probe,:) = get_start(TMat1(:,probe));
        end1(probe,:) = get_end(TMat1(:,probe));
        start2(probe,:) = get_start(TMat2(:,probe));
        end2(probe,:) = get_end(TMat2(:,probe));
    end
    
    start1 = [min(start1(:,1)), (min(start1(:,1))-1)*dt];
    end1 = [max(end1(:,1)), (max(end1(:,1))-1)*dt];
    start2 = [min(start2(:,1)), (min(start2(:,1))-1)*dt];
    end2 = [max(end2(:,1)), (max(end2(:,1))-1)*dt];

%     endindvec = [end1(:,1);end2(:,1)];
%     end1 = [max(endindvec),(max(endindvec)-1)*dt];
    
    tvec1 = tvec1(start1(1):end1(1))-start1(2);
    tvec2 = tvec2(start2(1):end2(1))-start2(2);
    TMat1 = TMat1(start1(1):end1(1),:);
    TMat2 = TMat2(start2(1):end2(1),:);
    
    
    % Save the modified data to TCell, compute standard deviation info,
    % save to TCell
    if i ~= 6 % data runs
        if length(tvec1) >= length(tvec2)
            TCell{1,i+1} = tvec1.';
            TMat2N = [TMat2; zeros(length(tvec1)-length(tvec2),4)+eqbT]; % append -195.8 to the values after equilibrium is reached
            TCell{2,i+1} = (TMat1 + TMat2N)/2; 
            TCell{3,i+1} = 1/(2*sqrt(2))*abs(TMat1 - TMat2N);% sigma, std. dev
            TCell{8,i+1} = TMat1;
            TCell{9,i+1} = TMat2N;
        elseif length(tvec1) < length(tvec2)
            TCell{1,i+1} = tvec2.';
            TMat1N = [TMat1; zeros(length(tvec2)-length(tvec1),4)+eqbT]; % append -195.8 to the values after equilibrium is reached
            TCell{2,i+1} = (TMat2 + TMat1N)/2; 
            TCell{3,i+1} = 1/(2*sqrt(2))*abs(TMat1N - TMat2);% sigma, std. dev
            TCell{8,i+1} = TMat1N;
            TCell{9,i+1} = TMat2;
        end
    elseif i == 6 % control runs
        if length(tvec1) >= length(tvec2)
            clear TMat1N
            clear TMat2N
            TCell{1,i+1} = tvec1.';
            TMat2N = [TMat2; zeros(length(tvec1)-length(tvec2),4)+eqbT]; % append -195.8 to the values after equilibrium is reached
            TCell{2,i+1} = (sum(TMat1,2) + sum(TMat2N,2))/8; 
            TMat = [TMat1, TMat2N];
            TCell{3,i+1} = std(TMat,0,2); %STD DEV
            
            TCell{8,i+1} = TMat1;
            TCell{9,i+1} = TMat2N;
        elseif length(tvec1) < length(tvec2)
            clear TMat1N
            clear TMat2N
            TCell{1,i+1} = tvec2.';
            TMat1N = [TMat1; zeros(length(tvec2)-length(tvec1),4)+eqbT]; % append -195.8 to the values after equilibrium is reached
            TCell{2,i+1} = (sum(TMat1,2) + sum(TMat1N,2))/8; 
            TMat = [TMat1, TMat1N];
            TCell{3,i+1} = std(TMat,0,2); %STD DEV
            
            TCell{8,i+1} = TMat1N;
            TCell{9,i+1} = TMat2;
        end
    end
    TCell{4,i+1} = TCell{2,i+1} + TCell{3,i+1}; %+1
    TCell{5,i+1} = TCell{2,i+1} + 2*TCell{3,i+1}; %+2
    TCell{6,i+1} = TCell{2,i+1} - TCell{3,i+1}; %-1
    TCell{7,i+1} = TCell{2,i+1} - 2*TCell{3,i+1}; %-2
    
%     TCell row description:
   % 1 is tvec
   % 2 is avg
   % 3 is sigma
   % 4 is +1
   % 5 is +2
   % 6 is -1
   % 7 is -2
   % 8 is run1 tared
   % 9 is run2 tared
   % columns are sphere sizes
    
    
    
    % plot the data:
    thiccness = 2;
    for probe = 1:4 
        hold on 
        if i~=4 || probe~=4 % don't plot the bad run that goes to -1E9 deg C
            plot(tvec1,TMat1(:,probe),'LineWidth',thiccness)
        end
        plot(tvec2,TMat2(:,probe),'LineWidth',thiccness)
        hold off 

% Plot curve from probe with error -- goes down to -1E+9 degrees C,
% negative 1 billion degrees, clear error.
%         if i == 4 && probe == 4
%             plot(tvec1,TMat1(:,probe))
%         end
    end
    
    xlabel('Time (sec)')
    ylabel(['Temperature (' char(176) 'C)'],'Interpreter','latex')
    title(SizeNames(i+1))
    set(gca,'FontSize',20)
    
    if i~=4 || probe~=4
        legend('Probe 1-1','Probe 2-1','Probe 1-2','Probe 2-2','Probe 1-3','Probe 2-3','Probe 1-4','Probe 2-4')
        
    else
        legend('Probe 1-1','Probe 2-1','Probe 1-2','Probe 2-2','Probe 1-3','Probe 2-3','Probe 2-4')
    end
    saveas(gcf,strcat('Raw-T-t-',SizeNames(i+1),'.jpg'))
end

% Note: sizes 1 and 3 (i.e. 1-38 and 1-63), as well as a little bit in size 2 (1-50) have wildly different results
% between the two trials. For 1 and 3, time to equilibrium differs by an
% order of magnitude. This will yield a big std. dev.

% Also, for trial 5 i=4 size 1-88, probe 4 failed.



% Note: Control run is just all the probes dunked in at once (see video from Arvindh). They should
% all be averaged together to get a single control T vs t response curve.
% The delay from t=0 to T=eqb is the time delay of the thermocouples.

%% Task 2 (cont.): plot sigma bounds for T vs t
close all; clc;
cd(FigPath)


for i = 0:6
    if i == 6
        figure()
        hold on
        plot(TCell{1,i+1},TCell{5,i+1}(:),'LineWidth',thiccness) % +2sigma
        plot(TCell{1,i+1},TCell{4,i+1}(:),'LineWidth',thiccness) % +1sigma
        plot(TCell{1,i+1},TCell{2,i+1}(:),'LineWidth',thiccness) % avg
        plot(TCell{1,i+1},TCell{6,i+1}(:),'LineWidth',thiccness) % -1sigma
        plot(TCell{1,i+1},TCell{7,i+1}(:),'LineWidth',thiccness) % -2sigma
%         plot(TCell{1,i+1},TCell{8,i+1}(:),'LineWidth',thiccness) % Run1
%         plot(TCell{1,i+1},TCell{9,i+1}(:),'LineWidth',thiccness) % Run2
        title(SizeNames(i+1))
        xlabel('Time (sec)')
        ylabel(['Temperature (' char(176) 'C)'],'Interpreter','latex')
        set(gca,'FontSize',20)
        legend('+2 $$\sigma$$','+1 $$\sigma$$','avg.','-1 $$\sigma$$','-2 $$\sigma$$','Interpreter','latex')
        saveas(gcf,strcat('T-t-',SizeNames(i+1),'.jpg'))
    end
    if i ~= 6
        for probe = 1:4
            figure()
            hold on
            plot(TCell{1,i+1},TCell{5,i+1}(:,probe),'LineWidth',thiccness) % +2sigma
            plot(TCell{1,i+1},TCell{4,i+1}(:,probe),'LineWidth',thiccness) % +1sigma
            plot(TCell{1,i+1},TCell{2,i+1}(:,probe),'LineWidth',thiccness) % avg
            plot(TCell{1,i+1},TCell{6,i+1}(:,probe),'LineWidth',thiccness) % -1sigma
            plot(TCell{1,i+1},TCell{7,i+1}(:,probe),'LineWidth',thiccness) % -2sigma
            plot(TCell{1,i+1},TCell{8,i+1}(:,probe),'LineWidth',thiccness) % Run1
            plot(TCell{1,i+1},TCell{9,i+1}(:,probe),'LineWidth',thiccness) % Run2
            title(strcat(SizeNames(i+1), ', ', 'probe ',num2str(probe)))
            xlabel('Time (sec)')
            ylabel(['Temperature (' char(176) 'C)'],'Interpreter','latex')
            set(gca,'FontSize',20)
            legend('+2 $$\sigma$$','+1 $$\sigma$$','avg.','-1 $$\sigma$$','-2 $$\sigma$$','Run 1','Run 2','Interpreter','latex')
            saveas(gcf,strcat('T-t-',SizeNames(i+1),'-','probe','-',num2str(probe),'.jpg'))
        end
    end
end



%% Task 3: Plot qdot
% This will depend only on outside temperatures, so average the data from
% probes 2, 3, 4. I want to take the average of the averages, NOT the
% average of all the data. This is because the average for each probe
% gives a decent estimate of what the maximum likelihood temperature will 
% be at that station, and I want to consider the ML temperature as the value. 
% Take average of these estimates to get an estimated average surface
% temperature.

% sum columns 2:4 and divide by 3 to get average surface temperature as a
% function of time

% I will also have to do the uncertainty on this averaging





%% Task 4: Plot mdot 
% (this will only be a very poor approximation, since we have no
% idea how much of the heat is dispersed throughout the reservoir of LN2)
% and how much actually goes into boiling.





%% Task 5: estimate maximum likelihood values of thermal parameters


% numerically compute Tdot(t) using deriv builtin
% Use qdot from task 3
% compute time-averaged value of h, plot h vs t and look for consistency

%% Functions
function ret = getstats(x,plotbool)
    [m,s] = normfit(x);
    if plotbool == true
        xplot = m-3*s:s/10:m+3*s;
        y = normpdf(xplot,m,s);
        figure()
        plot(xplot,y);
        hold on
        h = histogram(x,10*length(x),'Normalization','probability');
    end
    ret = [m-2*s, m-s, m, m+s, m+2*s];
end


function ret = get_start(y)
    dy = 0.510204075;
    y = y(1:ceil(length(y)/2)); % assume that the temp drop starts in the first half of the vector
    vector = y>max(y)-3; %3 degree change threshold (don't get caught out by fluctuations)
    lasteqbindex = find(vector,1,'last');
    ret = [lasteqbindex, y(lasteqbindex), (lasteqbindex-1) * dy]; % index, temp, time
end

function ret = get_end(y)
    dy = 0.510204075;
%     min(y); % degrees, arbitrary ending temp
    minval = min(y);
    if minval ~= y(end) && minval ~= y(end-1) && minval ~= y(end-2)
        vector = y<min(y)+2; % 2 degree threshold
        lasteqbindex = find(vector,1,'first')+2;
%     lasteqbindex = find(vector,1,'first')+1;
    
%     vector = vector(lastzeroindex:length(vector)) % add a cut on the vector so that we only get the positive values after it hits zero
%     index = find(vector,1,'first');
    else
        lasteqbindex = length(y);
    end
    ret = [lasteqbindex, y(lasteqbindex), (lasteqbindex-1) * dy]; % index, temp, time
end
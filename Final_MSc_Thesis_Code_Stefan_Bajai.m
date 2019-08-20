%% MSc Future Power Networks Thesis Code
% Name: Stefan Bajai
% Thesis Title: Impact of Domestic PV with Small Scale Storage Systems on the Distribution Network Operating Requirements and Performance
% Imperial College London 
% Department of Electrical & Electronics Engineering
% Date: August 2019
% Supervisor: Onyema Nduka

% Description of code: Simulates the IEEE European LV Test Feeder with 1-minute resolution PV profiles. The user is required to have OpenDSS installed to run this code and
% have all load and PV generation profiles available in the the same folder
% specified in the accompanying OpenDSS code. 

% For steps on how to replicate simulations please visit the GitHub Repository Link at:
% https://github.com/bajaiii/MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System.git

clear;
clc;
close all;

%% Scenario ID - Used for tracking Scenario #
Scenario = 'Scenario 1 - %d.%d.%d %s';
ID1 = 4;
ID2 = 1;
ID3 = 2;
Season = 'Winter (No PV or Battery Storage)';

%%
%   Personalised Matlab Colour Scheme
Colour1 = [0.2 0.8 1];
Colour2 = [0 .8 0];
Colour3 = [1 .5 1];
Colour4 = [1 .6 .4];
Colour5 = [1 0.35 0.35];
Colour6 = [153/255 51/255 1];
Colour7 = [25/255, 75/255, 1];
Colour8 = [51/255 1 51/255];
Colour9 = [1 .15 1];
Colour10 = [1 51/255 51/255];

% Starts OpenDSS Engine in MATLAB
[DSSStartOK, DSSObj, DSSText] = DSSStartup;

% Compiles Master_LV_IEEE.dss file - Need to have OpenDSS installed
DSSText.command='compile (C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\OpenDSS Script\Master_LV_IEEE.dss)';
    
% Set up the interface variables
DSSCircuit = DSSObj.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;

DSSText.command= 'set mode=yearly number= 1440 stepsize=1m';    % one day simulation 

%DSSText.command= 'set miniterations = 1'    %  Sets minimum iterations to solve at
%each time step - Default is 2 but reduced to 1 in time sequential study to
%improve speed

% DSSText.command= 'algortihm = newton'    % Changes solve method to Newton

DSSText.Command = 'Set number = 1';  % sets the solve command to only solve for 1 time interval (1-minute)

% Preallocation of matrices for speed
V1 = zeros(1440,907); % (1440 minutes and 907 buses)
V2 = zeros(1440,907);
V3 = zeros(1440,907);
ComplexVolts = zeros(1440,5442);
CircuitLosses = zeros(1440,2);
TransformerLosses = zeros(1440,2);
GridPower = zeros(1440,2);
PVInjectedPowers = zeros(1440,55);
ActiveLoadPowers = zeros(1440,55);
ReactiveLoadPowers = zeros(1440,55);
LineLosses = zeros(1440,2);
TransformerPower = zeros(1440,16);
% ElementLosses = zeros(1440,2038);

% Loop to extract power flow solution at each time step
    for i=1:1440
        
        DSSSolution.Solve;  % solves the circuit at one time interval
       
        V1(i,:) = DSSCircuit.AllNodeVmagPUByPhase(1); % Gets P.U RMS voltage magnitudes
        V2(i,:) = DSSCircuit.AllNodeVmagPUByPhase(2);
        V3(i,:) = DSSCircuit.AllNodeVmagPUByPhase(3);
    
        ComplexVolts(i,:) = DSSCircuit.AllBusVolts;          % Stores all complex voltages at each bus fir this time step
        CircuitLosses(i,:) = DSSCircuit.Losses;              % Stores entire circuit losses (Watt and Var) 
        LineLosses(i,:) = DSSCircuit.LineLosses;             % Stores all losses in line elements line losses (Watt and Var)
        ElementLosses(i,:) = DSSCircuit.AllElementLosses;    % Stores all circuit element losses (Watt and Var)
    
        TransformerLosses(i,:) = DSSCircuit.SubstationLosses;% Stores all transformer losses at each time step
        GridPower(i,:) = DSSCircuit.TotalPower;              % Stores total Power supplied/injected from/to grid (kW and kVar) at each time step
        
        DSSCircuit.SetActiveElement(['Transformer.tr1']);
        TransformerPower(i,:) = DSSCircuit.ActiveCktElement.Powers;% Stores all transformer powers at each time step
     
% Stores all injected PV powers, load and battery powers at each time step
for count=1:55  
    DSSCircuit.SetActiveElement(['PVSystem.pv_sys_' num2str(count)]);
    PVInjectedPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,1); % (no reactive power from PV i.e PF=1)
    
    DSSCircuit.SetActiveElement(['Load.load' num2str(count)]);
    ActiveLoadPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,1);
    ReactiveLoadPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,2);
    
    %%write if statement...if ID1==1,2...etc
    DSSCircuit.SetActiveElement(['Storage.battery' num2str(count)]);
    ActiveBatteryPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,1);
    ReactiveBatteryPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,2);
end


    end

%% PV POWERS VS BATTERY POWERS VS LOAD POWERS

[ROWS COLS] = size(ActiveLoadPowers);

% Preallocation of matrices for speed
AggragatedLoadPowers = zeros(1440,1)
AggragatedPVPowers = zeros(1440,1)
AggragatedBatteryPowers = zeros(1440,1)

% Get cumulative powers
for i=1:ROWS

        AggragatedLoadPowers(i,:) = sum(ActiveLoadPowers(i,:),'all');
        AggragatedPVPowers(i,:) = sum(PVInjectedPowers(i,:),'all');
        AggragatedBatteryPowers(i,:) = sum(ActiveBatteryPowers(i,:),'all');
end

Aggragated_Powers_Figure = figure('Name', ['Aggragated Powers ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
plot((1:ROWS)/60,AggragatedLoadPowers,'LineWidth',1,'color',Colour1);
hold on
plot((1:ROWS)/60,AggragatedPVPowers,'LineWidth',1,'color',Colour2);
plot((1:ROWS)/60,AggragatedBatteryPowers,'LineWidth',1,'color',Colour3);

InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.05, 1-InSet(1)-InSet(3)-0.1, 1-InSet(2)-InSet(4)-0.13]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Active Power (kW)','fontweight','bold','FontSize',8)
ylim([min(AggragatedPVPowers)-20, max(AggragatedLoadPowers)+10])
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Aggragated PV, Load & Storage Powers Vs. Time - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Loads','PVs','Batteries'},'location','southwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%

    
%%
NodeNames = DSSCircuit.AllNodeNames;        % Returns Node Names
BusNames = DSSCircuit.AllBusNames;          % Returns Bus Names
ElementNames = DSSCircuit.AllElementNames;  % Returns Circuit Element Names
% DSSText.Command ='Buscoords Buscoords.dat   ! load in bus coordinates'; %Returns coordinates of buses

%% Plots Bar Chart of Circuit Losses

TotalActiveLineLosses = sum(LineLosses(:,1)/60,'all');
TotalReactiveLineLosses = sum(LineLosses(:,2)/60,'all');

TotalActiveTransformerLosses = sum(TransformerLosses(:,1)/60,'all');
TotalReactiveTransformerLosses = sum(TransformerLosses(:,2)/60,'all');

TotalActiveLossesPlot = TotalActiveLineLosses + TotalActiveTransformerLosses;
TotalReactiveLossesPlot = TotalReactiveLineLosses + TotalReactiveTransformerLosses;

%Sets up data for stacked plot
StackedTotalLossesPower = [TotalActiveLineLosses,        TotalReactiveLineLosses; 
                           TotalActiveTransformerLosses, TotalReactiveTransformerLosses;
                           TotalActiveLossesPlot         TotalReactiveLossesPlot];
                       
StackedBarLossesFigure = figure('Name', ['Stacked Bar Chart Losses ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
StackedBarLosses = bar(StackedTotalLossesPower,'stacked','LineWidth',2);
set(StackedBarLosses(1), 'FaceColor', Colour1,'LineWidth',2,'EdgeColor','none');
set(StackedBarLosses(2), 'FaceColor', Colour2,'LineWidth',2,'EdgeColor','none');
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.05,InSet(2), 1-InSet(1)-InSet(3)-0.07, 1-InSet(2)-InSet(4)-0.1]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Apparent Energy Losses (kVA hours)','fontweight','bold','FontSize',8)
title({'Total Transformer & Line Energy Losses - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Active Energy Losses (kWh)','Reactive Energy Losses (kVArh)'},'location','east','AutoUpdate','off')
set(gca,'XTickLabel',{'All Lines','Transformer', 'Total Losses'});
% %%--%%--%%--PLOT STYLING--%%--%%--%%

%% Organises Transformer Powers

TransformerActivePower = TransformerPower(:,1) + TransformerPower(:,3) + TransformerPower(:,5); %3-Phase Transformer Active Power
TransformerReactivePower = TransformerPower(:,2) + TransformerPower(:,4) + TransformerPower(:,6);%3-Phase Transformer Reactive Power
TransformerApparentPower = abs(TransformerActivePower + j*TransformerReactivePower);

%% Plots Bar Chart of Transformer & Grid Energy

% Preallocation of matrices for speed
ActiveGridPower = zeros(1440,1);
ReactiveGridPower = zeros(1440,1);

% Takes only positive values of grid power (if injected into system) at
% each time step
for i=1:length(GridPower)
    
    % if positive active grid power then store it otherwise 0
    if - GridPower(i,1)>0
        ActiveGridPower(i) = abs(GridPower(i,1));
    else
        ActiveGridPower(i) = 0;
    end
    
    % if positive reactive grid power then store it otherwise 0
    if - GridPower(i,2)>0
        ReactiveGridPower(i) = abs(GridPower(i,2));
    else
        ReactiveGridPower(i) = 0;
    end
      
end

TotalActiveTransformerEnergy = abs(sum(TransformerActivePower/60,'all'));
TotalReactiveTransformerEnergy = abs(sum(TransformerReactivePower/60,'all'));

TotalActiveGridEnergy = abs(sum(ActiveGridPower/60,'all'));
TotalReactiveGridEnergy = abs(sum(ReactiveGridPower/60,'all'));

% TotalReactiveLineLosses = sum(LineLosses(:,2)/60,'all');
% TotalActiveTransformerLosses = sum(TransformerLosses(:,1)/60,'all');
% TotalReactiveTransformerLosses = sum(TransformerLosses(:,2)/60,'all');
% 
% TotalActiveLossesPlot = TotalActiveLineLosses + TotalActiveTransformerLosses;
% TotalReactiveLossesPlot = TotalReactiveLineLosses + TotalReactiveTransformerLosses;

%Sets up data for stacked plot
StackedTotalEnergy = [TotalActiveTransformerEnergy,        TotalReactiveTransformerEnergy; 
                           TotalActiveGridEnergy,               TotalReactiveGridEnergy;];
                       
StackedBarENERGYFigure = figure('Name', ['Stacked Bar Chart Energy ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
StackedBarEnergy = bar(StackedTotalEnergy,'stacked','LineWidth',2);
set(StackedBarEnergy(1), 'FaceColor', Colour1,'LineWidth',2,'EdgeColor','none');
set(StackedBarEnergy(2), 'FaceColor', Colour2,'LineWidth',2,'EdgeColor','none');
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.05,InSet(2), 1-InSet(1)-InSet(3)-0.07, 1-InSet(2)-InSet(4)-0.1]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Apparent Energy (kVA hours)','fontweight','bold','FontSize',8)
title({'Energy from Grid & on Transformer - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Active Energy (kWh)','Reactive Energy (kVArh)'},'location','southwest','AutoUpdate','off')
set(gca,'XTickLabel',{'Transformer','Grid'});
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Gets the phase to ground voltage magnitudes at every load
NumberofCircuitElements = DSSCircuit.NumCktElements; % Counts number of elements in circuit

Load_Information = readtable('IEEE_LV_TEST_FEEDER_Load_Info.csv');
Loads_Connected_to_Bus_No = Load_Information(2,2:end);
Loads_Connected_to_Bus_No = table2array(Loads_Connected_to_Bus_No);

% Preallocation of matrices for speed
V1Loads =zeros(1440,55);
V2Loads =zeros(1440,55);
V3Loads =zeros(1440,55);

 i=1;
    for k = Loads_Connected_to_Bus_No
        %Gets the phase to ground voltage magnitudes at every load
        V1Loads(:,i) = V1(:,k);
        V2Loads(:,i) = V2(:,k);
        V3Loads(:,i) = V3(:,k);
        i=i+1;
    end
    
%% Calculates voltage unbalance at each node

% Preallocation of matrices for speed
V1XCoor = zeros(1440,907);
V1YCoor = zeros(1440,907);
V2XCoor = zeros(1440,907);
V2YCoor = zeros(1440,907);
V3XCoor = zeros(1440,907);
V3YCoor = zeros(1440,907);

%Sorts Complex Bus Voltages
[CMPLXROWS, CMPLXCOLS] = size(ComplexVolts);
count =1; %should be 907 
for i=1:6:CMPLXCOLS

    V1XCoor(:,count) = ComplexVolts(:,i);
    V1YCoor(:,count) = ComplexVolts(:,i+1);
    V2XCoor(:,count) = ComplexVolts(:,i+2);
    V2YCoor(:,count) = ComplexVolts(:,i+3);
    V3XCoor(:,count) = ComplexVolts(:,i+4);
    V3YCoor(:,count) = ComplexVolts(:,i+5);
    count = count+1;

end

V1COMPLEXBUS = V1XCoor+j*V1YCoor;
V2COMPLEXBUS = V2XCoor+j*V2YCoor;
V3COMPLEXBUS = V3XCoor+j*V3YCoor;

% Preallocation of matrices for speed
V1COMPLEXLoads = zeros(1440,55);
V2COMPLEXLoads = zeros(1440,55);
V3COMPLEXLoads = zeros(1440,55);

 i=1; %initialisation
    for k = Loads_Connected_to_Bus_No
        %Gets the phase to ground complexvoltage magnitudes at every load
        V1COMPLEXLoads(:,i) = V1COMPLEXBUS(:,k);
        V2COMPLEXLoads(:,i) = V2COMPLEXBUS(:,k);
        V3COMPLEXLoads(:,i) = V3COMPLEXBUS(:,k);
        i=i+1;
    end

a_Fortescue = -0.5 + j*(sqrt(3)/2); % Fortescue's operator

Numerator = abs(V1COMPLEXLoads + ((a_Fortescue^2).*V2COMPLEXLoads) + (a_Fortescue.*V3COMPLEXLoads));
Denominator = abs(V1COMPLEXLoads + (a_Fortescue.*V2COMPLEXLoads) +((a_Fortescue^2).*V3COMPLEXLoads));
Unbalance = (Numerator./Denominator)*100; %definition of Voltage Unbalance according to IEC 61000-3-14)

%%
%-%-%-%-%-%-----Unbalance (%) at each Load Plot-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS, COLUMNS] = size(Unbalance);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
LoadNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,LoadNumbers);

%3D Surface Plot 
UnbalancePlotFigure = figure('Name', ['Unabalance(%) at all loads (IEC 61000) ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
UnbalancePlot = surf(x,y,(Unbalance)','EdgeColor','none','LineWidth',0.1);
hold on 

InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.05, 1-InSet(2)-InSet(4)-0.25]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% set(gca,'zscale','log')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Unbalance at all Loads', '(IEC 61000-3-14 Definition) (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Unbalance (%)')

%%--%%--%%--PLOT STYLING--%%--%%--%%

%%
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase A Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS, COLUMNS] = size(V1Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V1_3D_PLOTFigure = figure('Name', ['Phase A Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V1_3D_PLOT = surf(x,y,(V1Loads*240)','EdgeColor','none','LineWidth',0.1);
hold on 

view(-38,10)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.05, 1-InSet(2)-InSet(4)-0.25]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase A Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase A to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%

%% X-Axis View of VA
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase A Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS, COLUMNS] = size(V1Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V1_3D_PLOTFigure2 = figure('Name', ['Phase A Voltage at all Loads X-Axis', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V1_3D_PLOT2 = surf(x,y,(V1Loads*240)','EdgeColor','none','LineWidth',0.1);
hold on 

view(0,0)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.08, 1-InSet(2)-InSet(4)-0.25]);


%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase A Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase A to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%

%%
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase B Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS, COLUMNS] = size(V2Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V2_3D_PLOTFigure = figure('Name', ['Phase B Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V2_3D_PLOT = surf(x,y,(V2Loads*240)','EdgeColor','none','LineWidth',0.1)
hold on 

view(-38,10)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.05, 1-InSet(2)-InSet(4)-0.25]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase B Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase B to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%

%% X-Axis View of VB
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase B Vs. Loads-----%-%-%-%-%-%

% Gets size of V2 Mag Matrix
[ROWS, COLUMNS] = size(V2Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V2_3D_PLOTFigure2 = figure('Name', ['Phase B Voltage at all Loads X-Axis', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V2_3D_PLOT2 = surf(x,y,(V2Loads*240)','EdgeColor','none','LineWidth',0.1);
hold on 

view(0,0)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.08, 1-InSet(2)-InSet(4)-0.25]);


%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase B Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase B to Ground (V)')
%%--%%--%%--PLOT STYLING--%%--%%--%%

%%
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase C Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS, COLUMNS] = size(V3Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V3_3D_PLOTFigure = figure('Name', ['Phase C Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V3_3D_PLOT = surf(x,y,(V3Loads*240)','EdgeColor','none','LineWidth',0.1);
hold on 

view(-38,10)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.05, 1-InSet(2)-InSet(4)-0.25]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase C Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase C to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%

%% X-Axis View of VC
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase B Vs. Loads-----%-%-%-%-%-%

% Gets size of V2 Mag Matrix
[ROWS, COLUMNS] = size(V3Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x, y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V3_3D_PLOTFigure2 = figure('Name', ['Phase C Voltage at all Loads X-Axis', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V3_3D_PLOT2 = surf(x,y,(V3Loads*240)','EdgeColor','none','LineWidth',0.1);
hold on 

view(0,0)
InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.08, 1-InSet(1)-InSet(3)-0.08, 1-InSet(2)-InSet(4)-0.25]);


%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase C Voltage-to-Ground Magnitude', 'at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase C to Ground (V)')
%%--%%--%%--PLOT STYLING--%%--%%--%%

%% True Transformer Loading Power Plot

TransformerLoadingFig = figure('Name', ['Transformer Loading ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
bar((1:ROWS)/60,TransformerApparentPower,'LineWidth',1,'Facecolor',Colour1)
hold on
bar((1:ROWS)/60,TransformerActivePower,'LineWidth',1,'FaceColor',Colour2)
bar((1:ROWS)/60,TransformerReactivePower,'LineWidth',1,'Facecolor',Colour3)

InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.09,InSet(2)+0.06, 1-InSet(1)-InSet(3)-0.15, 1-InSet(2)-InSet(4)-0.15]);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Loading (Active & Reactive Power)','fontweight','bold','FontSize',8)
ylim([min(TransformerActivePower)-35, max(TransformerApparentPower)+10])
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer Loading (Active & Reactive Power) - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Apparent Power (kVA) (Magnitude)','Active Power (kW)','Reactive Power (kVAr)'},'location','southwest','FontSize',8,'AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Transformer Energy Plot

[ROWS, COLUMNS] = size(TransformerActivePower);

CumulativeTransformerEnergy_kWh =zeros(ROWS,1);

% Stores cumulative energy over the day
for c = 1:ROWS
    
    if c==1
    CumulativeTransformerEnergy_kWh(c) = abs(TransformerActivePower(c)/60);
    end
    
    if c >1
    CumulativeTransformerEnergy_kWh(c) = abs(TransformerActivePower(c)/60) + CumulativeTransformerEnergy_kWh(c-1);
    end
    
end

CumulativeEnergyFigure = figure('Name', ['Cumulative Transformer Energy ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
plot((1:ROWS)/60,CumulativeTransformerEnergy_kWh,'LineWidth',2,'color',Colour1);


%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Cumulative Energy (kWh)','fontweight','bold','FontSize',8)
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer Cumulative Energy Vs. Time - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
% legend({'Active Power(kW)'},'location','northwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Transformer Energy BARCHART Plot

TransformerEnergyTimeFig = figure('Name', ['Transformer Energy Vs. Time ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
bar((1:ROWS)/60,abs(TransformerActivePower/60),'FaceColor',Colour1)

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Energy (kWh)','fontweight','bold','FontSize',8)
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer Energy Vs. Time - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
% legend({'Active Power(kW)'},'location','northwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%

%% Transformer & Line Losses Plot

LossesFigure = figure('Name', ['Transformer & Line Losses ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
bar((1:ROWS)/60,LineLosses(:,1),'LineWidth',1,'Facecolor',Colour1)
hold on
bar((1:ROWS)/60,TransformerLosses(:,2),'LineWidth',1,'Facecolor',Colour2)
bar((1:ROWS)/60,LineLosses(:,2),'LineWidth',1,'Facecolor',Colour4)
bar((1:ROWS)/60,TransformerLosses(:,1),'LineWidth',1,'Facecolor',Colour3)

InSet = get(gca, 'TightInset');
set(gca, 'Position', [InSet(1)+0.06,InSet(2)+0.06, 1-InSet(1)-InSet(3)-0.1, 1-InSet(2)-InSet(4)-0.15]);


%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Losses (Active & Reactive Power)','fontweight','bold','FontSize',8)
ylim([0 max(LineLosses(:,1))+0.7])
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer & Line Losses - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Active Line Losses (kW)','Transformer Reactive Power (VAr)', 'Reactive Line Losses (kVAr)','Transformer Active Losses (kW)'},'location','northwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Interactive & Regular Plot Exports

saveas(StackedBarLossesFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Stacked_Bar_Chart_Losses_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(StackedBarENERGYFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Total_Grid_and_Transformer_Energy_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(UnbalancePlotFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\3_Phase_Unbalance_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V1_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Phase_A_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V2_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Phase_B_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V3_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Phase_C_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(TransformerLoadingFig, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Transformer_Loading_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(CumulativeEnergyFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Transformer_Cumulative_Energy_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(TransformerEnergyTimeFig, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Transformer_Energy_VS_Time_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(LossesFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Power_Losses_VS_Time_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(Aggragated_Powers_Figure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Interactive (MATLAB) Plots\Aggragated_Powers_VS_Time_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');

Aggragated_Powers_Figure.PaperUnits = 'inches';
Aggragated_Powers_Figure.PaperPosition = [0 0 3 2.5];
print(Aggragated_Powers_Figure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Aggragated_Powers_VS_Time_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

StackedBarLossesFigure.PaperUnits = 'inches';
StackedBarLossesFigure.PaperPosition = [0 0 3 2.5];
print(StackedBarLossesFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Stacked_Bar_Chart_Losses_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

StackedBarENERGYFigure.PaperUnits = 'inches';
StackedBarENERGYFigure.PaperPosition = [0 0 3 2.5];
print(StackedBarENERGYFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Total_Grid_and_Transformer_Energy_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

UnbalancePlotFigure.PaperUnits = 'inches';
UnbalancePlotFigure.PaperPosition = [0 0 3 2.5];
print(UnbalancePlotFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\3_Phase_Unbalance_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V1_3D_PLOTFigure.PaperUnits = 'inches';
V1_3D_PLOTFigure.PaperPosition = [0 0 3 2.5];
print(V1_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_A_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V1_3D_PLOTFigure2.PaperUnits = 'inches';
V1_3D_PLOTFigure2.PaperPosition = [0 0 3 2.5];
print(V1_3D_PLOTFigure2, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_A_3D_Voltage_Magnitude_Plot_x_Axis_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V2_3D_PLOTFigure.PaperUnits = 'inches';
V2_3D_PLOTFigure.PaperPosition = [0 0 3 2.5];
print(V2_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_B_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V2_3D_PLOTFigure2.PaperUnits = 'inches';
V2_3D_PLOTFigure2.PaperPosition = [0 0 3 2.5];
print(V2_3D_PLOTFigure2, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_B_3D_Voltage_Magnitude_Plot_x_Axis_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V3_3D_PLOTFigure.PaperUnits = 'inches';
V3_3D_PLOTFigure.PaperPosition = [0 0 3 2.5];
print(V3_3D_PLOTFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_C_3D_Voltage_Magnitude_Plot_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

V3_3D_PLOTFigure2.PaperUnits = 'inches';
V3_3D_PLOTFigure2.PaperPosition = [0 0 3 2.5];
print(V3_3D_PLOTFigure2, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Phase_C_3D_Voltage_Magnitude_Plot_x_Axis_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

TransformerLoadingFig.PaperUnits = 'inches';
TransformerLoadingFig.PaperPosition = [0 0 3 2.5];
print(TransformerLoadingFig, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Transformer_Loading_VS_Time_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');

LossesFigure.PaperUnits = 'inches';
LossesFigure.PaperPosition = [0 0 3 2.5];
print(LossesFigure, ['C:\Users\bajai\Documents\GitHub\MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System\Plots\Non-interactive Plots (PNG)\Transformer_Line_Losses_VS_Time_' sprintf(Scenario,ID1,ID2,ID3,Season) '.png'], '-dpng','-r600');
%% MSc Future Power Networks Thesis Code
% Name: Stefan Bajai
% Thesis Title: Impact of Domestic PV with Small Scale Storage Systems on the Distribution Network Operating Requirements and Performance
% Imperial College London 
% Department of Electrical & Electronics Engineering
% Date: August 2019
% Supervisor: Onyema Nduka

% Description of code: The user is required to have OpenDSS installed to run this code and
% have all load and PV generation profiles available in the the same folder
% specified in the accompanying OpenDSS code. 

% GitHub Link: https://github.com/bajaiii/MSc-Project---Impact-of-PV-and-Battery-Storage-on-Distribution-System.git

clear all
clc
close all

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
DSSText.command='compile (C:\Users\bajai\Documents\University\Imperial College London\MSc Project\OpenDSS\Master_LV_IEEE.dss)';
    
% Set up the interface variables
DSSCircuit = DSSObj.ActiveCircuit;
DSSSolution = DSSCircuit.Solution;

DSSText.command= 'set mode=yearly number= 1440 stepsize=1m'    % one day simulation 

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
     
% Stores all injected PV powers and load powers at each time step
for count=1:55  
    DSSCircuit.SetActiveElement(['PVSystem.pv_sum_sys_' num2str(count)]);
    PVInjectedPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,1); % (no reactive power from PV i.e PF=1)
    
    DSSCircuit.SetActiveElement(['Load.load' num2str(count)]);
    ActiveLoadPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,1);
    ReactiveLoadPowers(i,count) = DSSCircuit.ActiveCktElement.Powers(:,2);
end


    end
    
%%
NodeNames = DSSCircuit.AllNodeNames;        % Returns Node Names
BusNames = DSSCircuit.AllBusNames;          % Returns Bus Names
ElementNames = DSSCircuit.AllElementNames;  % Returns Circuit Element Names

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
set(StackedBarLosses(1), 'FaceColor', Colour1,'LineWidth',2);
set(StackedBarLosses(2), 'FaceColor', Colour2,'LineWidth',2);

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Circuit Losses Apparent Energy Losses (kVA hours)','fontweight','bold','FontSize',8)
title({'Total Distribution Network Energy Losses (Active & Reactive Energy Losses) - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Active Energy Losses (kWh)','Reactive Energy Losses (kVArh)'},'location','northwest','AutoUpdate','off')
set(gca,'XTickLabel',{'Total Line Losses','Total Transformer Losses', 'Total Losses'});
% %%--%%--%%--PLOT STYLING--%%--%%--%%

%StoresHandles
StackedTotalLossesPowerX = StackedBarLosses.XData;
StackedTotalLossesPowerY = StackedBarLosses.YData;
StackedTotalLossesPowerHandles = [StackedTotalLossesPowerX StackedTotalLossesPowerY ];

%% Organises Transformer Powers

TransformerActivePower = TransformerPower(:,1) + TransformerPower(:,3) + TransformerPower(:,5); %3-Phase Transformer Active Power
TransformerReactivePower = TransformerPower(:,2) + TransformerPower(:,4) + TransformerPower(:,6);%3-Phase Transformer Reactive Power
TransformerApparentPower = abs(TransformerActivePower + j*TransformerReactivePower);

%% Gets the phase to ground voltage magnitudes at every load
NumberofCircuitElements = DSSCircuit.NumCktElements % Counts number of elements in circuit

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
[CMPLXROWS CMPLXCOLS] = size(ComplexVolts);
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
[ROWS COLUMNS] = size(Unbalance);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
LoadNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x y] = meshgrid(Minutes,LoadNumbers);

%3D Surface Plot 
UnbalancePlotFigure = figure('Name', ['Unabalance(%) at all loads (IEC 61000) ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
UnbalancePlot = surf(x,y,(Unbalance)','EdgeColor','none','LineWidth',0.1)
hold on 

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% set(gca,'zscale','log')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Unbalance at all Loads (IEC 61000-3-14 Definition) (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Unbalance (%)')

%%--%%--%%--PLOT STYLING--%%--%%--%%

%%
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase A Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS COLUMNS] = size(V1Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V1_3D_PLOTFigure = figure('Name', ['Phase A Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V1_3D_PLOT = surf(x,y,(V1Loads*240)','EdgeColor','none','LineWidth',0.1)
hold on 

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase A Voltage-to-Ground Magnitude at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
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
[ROWS COLUMNS] = size(V2Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V2_3D_PLOTFigure = figure('Name', ['Phase B Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V2_3D_PLOT = surf(x,y,(V2Loads*240)','EdgeColor','none','LineWidth',0.1)
hold on 

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase B Voltage-to-Ground Magnitude at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase B to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%

%%
%-%-%-%-%-%-----Voltage-to-Ground Plot Phase C Vs. Loads-----%-%-%-%-%-%

% Gets size of V1 Mag Matrix
[ROWS COLUMNS] = size(V3Loads);

% Sets x and y axis
Minutes = [(1:ROWS)/60]';
BusNumbers = [1:COLUMNS]';

% Sets up meshgrid
[x y] = meshgrid(Minutes,BusNumbers);

%3D Surface Plot 
V3_3D_PLOTFigure = figure('Name', ['Phase C Voltage at all Loads ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
V3_3D_PLOT = surf(x,y,(V3Loads*240)','EdgeColor','none','LineWidth',0.1)
hold on 

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
% grid on;
colormap(jet)
shading interp
grid minor;
title({'Phase C Voltage-to-Ground Magnitude at all Loads (1-Min Resolution)' sprintf(Scenario,ID1,ID2,ID3,Season)})
xlabel('Hour')
xlim([0 ROWS/60])
ylabel('Load #')
ylim([0 COLUMNS])
zlabel('Voltage Magnitude Phase C to Ground (V)')
% zlim([0.95 1.01])
%%--%%--%%--PLOT STYLING--%%--%%--%%


%% True Transformer Loading Power Plot

TransformerLoadingFig = figure('Name', ['Transformer Loading ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
plot((1:ROWS)/60,TransformerActivePower,'LineWidth',1,'color',Colour1)
hold on
plot((1:ROWS)/60,TransformerReactivePower,'LineWidth',1,'color',Colour2)
plot((1:ROWS)/60,TransformerApparentPower,'LineWidth',1,'color',Colour3)

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Loading (Active & Reactive Power)','fontweight','bold','FontSize',8)
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer Loading (Active & Reactive Power) - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Active Power(kW)','Reactive Power(kVAr)','Apparent Power (kVA) (Magnitude)'},'location','northwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Transformer Energy Plot

[ROWS COLUMNS] = size(TransformerActivePower)

CumulativeTransformerEnergy_kWh =zeros(ROWS,1);


for c = 1:ROWS
    
    if c==1
    CumulativeTransformerEnergy_kWh(c) = abs(TransformerActivePower(c)/60)
    end
    
    if c >1
    CumulativeTransformerEnergy_kWh(c) = abs(TransformerActivePower(c)/60) + CumulativeTransformerEnergy_kWh(c-1);
    end
    
end



CumulativeEnergyFigure = figure('Name', ['Cumulative Transformer Energy ', sprintf(Scenario,ID1,ID2,ID3,Season) ]);
plot((1:ROWS)/60,CumulativeTransformerEnergy_kWh,'LineWidth',2,'color',Colour1)


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
plot((1:ROWS)/60,TransformerLosses(:,1),'LineWidth',1,'color',Colour1)
hold on
plot((1:ROWS)/60,TransformerLosses(:,2),'LineWidth',1,'color',Colour2)
plot((1:ROWS)/60,LineLosses(:,1),'LineWidth',1,'color',Colour3)
plot((1:ROWS)/60,LineLosses(:,2),'LineWidth',1,'color',Colour4)

%%--%%--%%--PLOT STYLING--%%--%%--%%
set(gca, 'FontName', 'Times New Roman','FontSize',8,'TickLength', [.03 .03] ,'XMinorTick', 'on','YMinorTick'  , 'on')
grid on;
grid minor;
ylabel('Transformer Losses (Active & Reactive Power)','fontweight','bold','FontSize',8)
xlabel('Hour','fontweight','bold','FontSize',8)
xlim([0 ROWS/60])
title({'Transformer & Line Losses (Active & Reactive Power) - ELVTF ' sprintf(Scenario,ID1,ID2,ID3,Season)},'FontSize',8)
legend({'Transformer Active Losses (kW)','Transformer Reactive Power(VAr)', 'Active Line Losses (kW)', 'Reactive Line Losses (kVAr)'},'location','northwest','AutoUpdate','off')
% %%--%%--%%--PLOT STYLING--%%--%%--%%


%% Plot Exports

% StackedBarLosses
% V1_3D_PLOT
% V2_3D_PLOT
% V3_3D_PLOT
% 
% savefig(StackedTotalLossesPowerHandles,'Stacked_Bar_.fig')
saveas(StackedBarLossesFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(UnbalancePlotFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V1_3D_PLOTFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V2_3D_PLOTFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(V3_3D_PLOTFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');
saveas(StackedBarLossesFigure, ['Stacked_Bar_Chart_Losses_' sprintf(Scenario,ID1,ID2,ID3,Season) '.fig'], 'fig');

% ['Scenario_' num2str(ID1) '_' num2str(ID2) '_' num2str(ID3) '_Stacked_Bar_.fig'])

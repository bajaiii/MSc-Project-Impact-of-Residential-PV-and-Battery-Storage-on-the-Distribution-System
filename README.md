# MSc-Project: Impact of PV and Battery-Storage on Distribution System

**Course:** MSc Future Power Networks 

**Name:** Stefan Bajai

**Project Title:** Impact of Domestic PV with Small Scale Storage Systems on the Distribution Network Operating Requirements and Performance

**Project Description:** 3-phase Modelling of UK LV Distribution System (IEEE low-voltage test feeder network) using OpenDSS to determine steady-state operating points of the network. Load and PV profiles with 1-minute resolution are used to run a quasi-static load flow simulation solving at each time step for each phase of the distribution network.

Developed and tested on **MATLAB R2018b** & **OpenDSS Version 8.5.9.1 (64-Bit)**

**While @ Imperial College London, 
 Department of Electrical & Electronics Engineering**

**Date:** August 2019

## Replicating Simulations

**Step 1:** Install MATLAB & OpenDSS (ensure both are 64-bit versions for compatibility). During OpenDSS installation make sure the OpenDSS COM Engine is registered. Usually done automatically during installation but can check by opening VBA in Excel (**hold alt & F11** while in Excel) then **>** tools **>** references and check if the OpenDSS Engine appears. If it is, the COM Engine is installed correctly. The COM Engine enables interfacing between MATLAB and OpenDSS (i.e all unbalanced load flow simulations can be ran from MATLAB directly and the solutions of each simulation can be presented using MATLAB)

OpenDSS can be can be downloaded from: **https://sourceforge.net/p/electricdss/wiki/Home/**. This page also specifies the key features of OpenDSS.

**Step 2:** Copy the files/folders '*DSSStartup.m*', '*Buscoords.txt*', '*Load_Profiles*', '*Final_MSc_Thesis_Code_Stefan_Bajai.m*', and '*Master_LV_IEEE.dss*', to the same location. 

**Step 3:** Change the scenario you wish to simulate in the *'Master_LV_IEEE.dss'* using OpenDSS. This can be done by commenting out definitions of PV elements and load shapes in the code. The scenarios for each simulation are described in the report. In the OpenDSS scripting language, comment lines can be added line-by-line by inserting an **'!'** at the beginning of the line or, alternatively and more appropriate in this case, is to use the block comment by inserting **'/*'** before the code you wish to comment out and **'*/'** after the code you wish to comment out. 

**Step 4:** Run the '*Final_MSc_Thesis_Code_Stefan_Bajai.m*' file in matlab and display the solutions to the power flow study. 




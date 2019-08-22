# MSc Project: Impact of Residential PV and Battery Storage on the Distribution System

**Course:** MSc Future Power Networks 

**Name:** Stefan Bajai

**Project Title:** Impact of Domestic PV with Small Scale Storage Systems on the Distribution Network Operating Requirements and Performance

**Project Description:** 3-phase Modelling of UK LV Distribution System (IEEE low-voltage test feeder network) using OpenDSS to determine steady-state operating points of the network. Load and PV profiles with 1-minute resolution are used to run a quasi-static load flow simulation solving at each time step for each phase of the distribution network.

Developed and tested on **MATLAB R2018b** & **OpenDSS Version 8.5.9.1 (64-Bit)**

**While @ Imperial College London, 
 Department of Electrical & Electronics Engineering**

**Date:** August 2019

## Replicating Simulations

**Step 1:** Install MATLAB & OpenDSS (ensure both are 64-bit versions for compatibility). During OpenDSS installation make sure the OpenDSS COM Engine is registered. Usually done automatically during installation but can check by opening VBA in Excel (**hold alt & F11** while in Excel) then **>** tools **>** references and check if the OpenDSS Engine appears. If it does appear, the COM Engine is installed correctly. The COM Engine enables interfacing between MATLAB and OpenDSS (i.e all 3-phase/unbalanced load flow simulations can be ran from MATLAB directly and the solutions of each simulation can be presented using MATLAB)

OpenDSS can be can be downloaded from: **https://sourceforge.net/p/electricdss/wiki/Home/**. This page also specifies the key features of OpenDSS.

**Step 2:** Copy all files and folders from this rpeository to your hard drive. Open the'*Final_MSc_Thesis_Code_Stefan_Bajai.m*' and execute the script. 

**Step 3:** MATLAB will prompt the user which scenario they wish to simulate. The options are between 1-10. Once a selection has been made, the same Scenario will be replicated.

**Step 4:** Inspect the results. 



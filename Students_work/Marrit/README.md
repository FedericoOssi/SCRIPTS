# README

This folder contains the scripts that are used for the BSc thesis of Marrit Leenstra. 

### Title: 
Upslope, downslope: the influence of the third dimension on step length of roe deer

### Abstract: 
Ecological questions regarding animal behavior, response to external factors and intrinsic motivators can all be addressed by analyzing animal movement data, often obtained by (GPS) tracking devices. The so obtained locations can be most accurately described by three coordinates; latitude, longitude and elevation. In the analysis of terrestrial movement data, the elevation is nevertheless often ignored. In this study an attempt has been made to identify under what conditions it is important to consider one of the most basic movement metrics, step length, in 3D. 

The difference between 3D and 2D step lengths of 0 – 1000m has been calculated for constant, concave and rugged slopes ranging from 0 – 60°. Since the 2D definition did not hold for 3D step lengths on rugged slopes, it has been redefined to the Euclidean surface distance. The difference is subsequently calculated for the tracking steps of two contrasting roe deer datasets, one in low relief terrain and one in high relief terrain. The elevation at the start and endpoint of each tracking step as well as at every 10m along the tracking step was extracted from a Digital Elevation Model (DEM) using bi-linear interpolation.

The theoretical difference increased with increasing slope and with increasing rugosity, although a large variation in the effect size of rugosity was found. The theoretical difference for concave slopes was slightly higher than constant slopes. When applied to the roe deer movement data, the median bias was estimated at 7.3% in the high relief area and 0.1% in low relief area, while the highest median bias for one individual was found to be 18.1% in the high relief area and only 0.2% in the low relief area. The minimum underestimation could be accurately estimated by the theoretical difference on constant slopes. While rugosity leads to an increase in bias, there was found variation in the magnitude. It is therefore recommended that the step length is measured in 3D when the studied species is expected to make use of steep and rugged terrain. 

The following files are included:

* [SCRIPTS/Students_work/Marrit/Difference between 3D and 2D steplength for roe deer in alpine and relatively flat studyareas](Difference between 3D and 2D steplength for roe deer in alpine and relatively flat studyareas.md)

This code is used in the empirical part of the BSc thesis, and contains the analysis of the roe deer movement data. The studyareas were located in Germany (low relief, studyarea 15 in the EURODEER database) and Switzerland (high relief, studyarea 25 in the EURODEER database). 
### SQLcode: 
Code used in preprocessing of the data in the database by subsampling the data to 30’ temporal resolution and subsequently selecting the best year for every animal (i.e. highest proportion of successful location fixes between the 1st of March and the 31st of October) then selecting randomly 20 animals with a proportion of successful fixes greater than 70% (10 animals Germany) and 90% (10 animals Switzerland) (author Johannes de Groeve)
### Theoretical difference 3D and 2D FPT at constant slopes 
This file contains the script that is used to calculate the theoretical difference between 3D and 2D First Passage Time on constant slopes. This was just an example of how the third dimension can also influence other movement metrics and needs to be further developed. 
### Theoretical difference 3D and 2D step length at concave slopes 
This script is used to calculate the difference between 2D and surface (3D) step length on concave slopes. Only one kind of concavety is used (varying only the 'a' in 'z = ax^2 + bx + c'), maybe more shapes of concave slopes can be examined in the future. 
### Theoretical difference 3D and 2D step length at constant slopes 
This script is used to calculate the difference between 3D and 2D step length on constant slopes (as the name already suggests…), which is a deterministic relation and can be used to asses the minimal difference between 3D and 2D step length.
### Theoretical difference between 3D and 2D step lengths on a rugged slope 
This script is used to calculate the difference between 2D and surface step length on rugged slopes. Rugged slopes are what is most often encountered in nature, however, I was not able to pinpoint how the relation rugged slope - difference between 3D and 2D step length is exactly looking. It can however be said that in general more rugosity leads to an increase in 3D distance.

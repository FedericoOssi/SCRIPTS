# SQL-code regularizing trajectories 

This SQL-code is used to reglarize the trajectories on 30 minutes data in the EURODEER database. It is mainly a subsampling needed because one of the two studyareas used a temporal resolution of 15 minutes, whereas the other one used 30 minutes.

```
create table temp.marrit_gps_data AS 
(
SELECT 
(tools.regularize(animals_id, 
1800, 300, -- interval, buffer
date_trunc('hour',min(acquisition_time))::timestamp with time zone, -- start_time (first fix)
date_trunc('hour',max(acquisition_time))::timestamp with time zone)).* -- end_time (1 year later)
FROM main.gps_data_animals  
WHERE animals_id in (select animals_id from main.animals where study_areas_id in (25,15)) 
GROUP BY animals_id ORDER BY animals_id, acquisition_time
);
```

Code used to select 10 trajectories for the German studyarea, first selecting the best year for every animal (i.e. highest proportion of succesful location fixes between the 1st of March and the 31st of October) then take a random selection of animals with a proportion of succesful fixes greater than 70%. 

```
select setseed(0.21);
-- germany 15
CREATE TABLE temp.marrit_de15 AS (
SELECT study_areas_id, gg.animals_id, gg.yyear, acquisition_time, geom, fixes_o, fixes_e, prop
	FROM temp.marrit_gps_data mm,	
	(
		SELECT * FROM (
		SELECT *, row_number() over (partition by study_areaS_id order by random() ) r2 FROM (
		SELECT * FROM (
		SELECT * FROM (
		SELECT *, 
			row_number() over (partition by animals_id order by animals_id,prop desc) r1
			FROM 
		(SELECT study_areas_id, animals_id, ((extract(doy from '2018-08-31'::date) - extract(doy from '2018-03-01'::date)) * 48) + 48 fixes_e,
		COUNT(*)/(((extract(doy from '2018-08-31'::date) - extract(doy from '2018-03-01'::date)) * 48)+48) *100 prop,
		COUNT(*) fixes_o,extract(year from aa.acquisition_time) yyear

		FROM temp.marrit_gps_data aa
		JOIN main.animals USING (animals_id)
		WHERE study_areas_id in (15) and extract(month from aa.acquisition_time) between 3 and 8 and geom is not null
		group by animals_id, yyear,study_areas_id
		ORDER BY study_areas_id, animals_id, prop) bb) cc  where r1 = 1  
		) dd where prop > 70) ee ) ff WHERE r2 < 11 
	) gg 
	WHERE gg.animals_id = mm.animals_id and 
	gg.yyear= extract(year from mm.acquisition_time) 
	and extract(month from acquisition_time) between 3 and 8
	order by gg.animals_id, acquisition_time
);
```

Code used to select 10 trajectories for the Swiss studyarea, first selecting the best year for every animal (i.e. highest proportion of succesful location fixes between the 1st of March and the 31st of October) then take a random selection of animals with a proportion of succesful fixes greater than 90%. 

```
-- swiss 25
select setseed(0.21);
CREATE TABLE temp.marrit_ch25 AS (
	SELECT study_areas_id, gg.animals_id, gg.yyear, acquisition_time, geom, fixes_o, fixes_e, prop 
		FROM temp.marrit_gps_data mm,	
		(
			SELECT * FROM (
			SELECT *, row_number() over (partition by study_areaS_id order by random() ) r2 FROM (
			SELECT * FROM (
			SELECT * FROM (
			SELECT *, 
				row_number() over (partition by animals_id order by animals_id,prop desc) r1
				FROM 
			(SELECT study_areas_id, animals_id, ((extract(doy from '2018-08-31'::date) - extract(doy from '2018-03-01'::date)) * 48) + 48 fixes_e,
			COUNT(*)/(((extract(doy from '2018-08-31'::date) - extract(doy from '2018-03-01'::date)) * 48)+48) *100 prop,
			COUNT(*) fixes_o,extract(year from aa.acquisition_time) yyear

			FROM temp.marrit_gps_data aa
			JOIN main.animals USING (animals_id)
			WHERE study_areas_id in (25) and extract(month from aa.acquisition_time) between 3 and 8 and geom is not null
			group by animals_id, yyear,study_areas_id
			ORDER BY study_areas_id, animals_id, prop) bb) cc  where r1 = 1  
			) dd where prop > 90) ee ) ff WHERE r2 < 11 
		) gg 
		WHERE gg.animals_id = mm.animals_id and 
		gg.yyear= extract(year from mm.acquisition_time) 
		and extract(month from acquisition_time) between 3 and 8
		order by animals_id, acquisition_time
	);	
  
```



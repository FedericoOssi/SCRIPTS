# DATABASE ACCESS

To connect a program to a database you need the database name, host, port, user name and password.

## CONTENT 

* [psql](#psql)
* [r](#r)
* [grass](#grass)
* [qgis](#qgis)


#### psql

```bash
psql -h <host> -p 5432 -d eurodeer_db -U <myname>  
```

###### [-to content-](#content)

#### r

**RPostgreSQL**  
```R
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="eurodeer_db", host="<host>",port="5432", user="<myname>", password="<mypass>")
```

# Import from postgresql to R with RPostgreSQL

```diff
- #### NOTE THAT TIMESTAMPS AND NUMBERS IN DOUBLE PRECISION, SUCH AS COORDINATES (Lon/Lat) NEED TO BE CONVERTED INTO CHARACTER STRINGS WITHIN THE QUERY. OTHERWISE TIMESTAMPS ARE SHIFTED AND COORDINATES ARE ROUNDED!!!!!!! 
```
<span style="color:red;">Word up</span>

```R

# QUERY
q <- paste0("SELECT gps_data_animals_id, geom, a.animals_id, gps_sensors_id, acquisition_time::character varying, longitude::character varying, latitude::character varying FROM main.gps_data_animals a WHERE animals_id = 1 AND gps_validity_code = 1 ORDER BY animals_id, gps_sensors_id, acquisition_time")

# GET DATA
rs <- dbSendQuery(conn=con, q)
data <- fetch(rs,-1)
dbClearResult(rs) 
```

**rpostgis**  
```R
library(rpostgis)
con <- dbConnect("PostgreSQL", dbname="eurodeer_db", host="<host>", user="<myname>", password="<mypass>") 
pgPostGIS(con) # test connection
```

# Import from postgresql to R with rpostgis
```R

# QUERY
q <- paste0("SELECT gps_data_animals_id, geom, a.animals_id, gps_sensors_id, acquisition_time::character varying, longitude::character varying, latitude::character varying FROM main.gps_data_animals a WHERE animals_id = 1 AND gps_validity_code = 1 ORDER BY animals_id, gps_sensors_id, acquisition_time")

# GET SPATIAL DATA 
d <- pgGetGeom(conn=con, query=q)

###### [-to content-](#content)

#### grass

```bash
db.connect driver=pg database="host=<host>,dbname=eurodeer_db,port=5432" 
db.login user=<myname> pass=<mypass>
db.tables
```
###### [-to content-](#content)

#### qgis

**qgis**  

###### [-to content-](#content)

###### [-TO README-](README.md)


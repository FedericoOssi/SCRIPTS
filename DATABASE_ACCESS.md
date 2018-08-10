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

**rpostgis**  
```R
library(rpostgis)
con <- dbConnect("PostgreSQL", dbname="eurodeer_db", host="<host>", user="<myname>", password="<mypass>") 
pgPostGIS(con) # test connection
```
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

# DATABASE ACCESS

## CONTENT 

* [psql](#psql)
* [r](#r)
* [grass](#grass)
* [qgis](#qgis)


## psql

**psql**  
```bash
psql -h eurodeer2.fmach.it -p 5432 -d eurodeer_db -U <myname>  
```

###### [-to content-](#content)

## r

**RPostgreSQL**  
```R
library(RPostgreSQL)
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname="eurodeer_db", host="eurodeer2.fmach.it",port="5432", user="<myname>", password="<mypass>")
```

**rpostgis**  
```R
library(rpostgis)
con <- dbConnect("PostgreSQL", dbname="eurodeer_db", host="eurodeer2.fmach.it", user="<myname>", password="<mypass>") 
pgPostGIS(con) # test connection
```



###### [-to content-](#content)

## grass

**grass**  
```grass
db.connect driver=pg database="host=eurodeer2.fmach.it,dbname=eurodeer_db,port=5432" 
db.login user=<myname> pass=<mypass>
db.tables
```

###### [-to content-](#content)

## qgis

**qgis**  


###### [-to content-](#content)

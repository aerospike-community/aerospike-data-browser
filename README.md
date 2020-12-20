# Aerospike Data Browser

The purpose of this project is to let users quickly browse data in Aerospike.

## Components
* [Quix](https://github.com/wix/quix)
* [Presto](https://prestosql.io/)
* [Aerospike Connect for Presto](https://github.com/citrusleaf/aerospike-connect-presto)

## Quick start
Run Data Browser in a Docker container
```bash
docker build . -t aerospike-data-browser
docker run -d -p 3000:3000 -p 8081:8081 --name data-browser aerospike-data-browser
```

## Configuration
Set environment variables if necessary.

| Variable | Description | Default Value |
| --- | --- | --- |
| AS_HOSTLIST | Aerospike host list, a comma separated list of potential hosts to seed the cluster. |  |
| TABLE_DESC_DIR | Path of the directory containing table description files. | /usr/lib/presto/etc/aerospike |
| SPLIT_NUMBER | Number of Presto splits. See Parallelism section for more information. | 4 |
| CACHE_TTL_MS | Schema inference cache TTL in milliseconds. | 1800000 |
| DEFAULT_SET_NAME | Table name for the default set. | __default |
| RECORD_KEY_NAME | Column name for the record's primary key. | __key |
| RECORD_KEY_HIDDEN | If set to false, the primary key column will be available in the result set. | true |
| INSERT_REQUIRE_KEY | Require the primary key on INSERT queries. Although we recommend that you provide a primary key, you can choose not to by setting this property to false, in which case a UUID is generated for the PK. You can view it by setting aerospike.record-key-hidden to false for future queries. | true |

## Main features
- [Query management](#Management) - organize your notebooks in folders for easy access and sharing
- [Visualizations](#Visualizations) - quickly plot time and bar series (more visualizations to follow)
- [DB Explorer](#Explorer) - explore your data sources
- Search - search notes of all users

#### Management
![](documentation/docs/assets/management.gif)

#### Visualizations
![](documentation/docs/assets/chart.gif)

#### Explorer
![](documentation/docs/assets/db.gif)

## License
MIT

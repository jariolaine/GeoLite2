# GeoLite2

Maxmind GeoLite2 CSV to Oracle database

### Prerequisites

Oracle 11G XE database on Linux server

### Installing

Create directories to database server
```
mkdir -p /opt/geolite2/data
mkdir /opt/geolite2/log
mkdir /opt/geolite2/script
```

Give privileges to dba group to server directories
```
chgrp dba /opt/geolite2/data
chgrp dba /opt/geolite2/log
chmod g+w /opt/geolite2/data
chmod g+w /opt/geolite2/log
```

Create dummy files to server
```
touch /opt/geolite2/data/GeoLite2-ASN-CSV.zip
touch /opt/geolite2/data/GeoLite2-City-CSV.zip
```

Change oracle as owner of dummy files
```
chown oracle /opt/geolite2/data/GeoLite2-ASN-CSV.zip
chown oracle /opt/geolite2/data/GeoLite2-City-CSV.zip
```

Place script download_data.sh to directory /opt/geolite2/script.

Give execute privilege to dba group
```
chgrp dba /opt/geolite2/script/download_data.sh
chmod g+x opt/geolite2/script/download_data.sh
```

Install database objects

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


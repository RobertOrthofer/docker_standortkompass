#!/bin/bash

/usr/bin/java -jar /photon/photon-0.3.0.jar -nominatim-import -host nominatim -port 5432 -languages de
/usr/bin/java -jar /photon/photon-0.3.0.jar -host nominatim -port 5432
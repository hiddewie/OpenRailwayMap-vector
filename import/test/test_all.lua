package.path = package.path .. ";test/?.lua"

-- Logic
require('test_openrailwaymap')

-- TODO delete
require('test_import_node')
require('test_import_relation')

-- Features
require('test_import_box')
require('test_import_catenary')
require('test_import_platform')
require('test_import_poi')
require('test_import_railway_line')
require('test_import_station')
require('test_import_turntable')

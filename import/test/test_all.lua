package.path = package.path .. ";test/?.lua"

-- Logic
require('test_openrailwaymap')

-- Features
require('test_import_box')
require('test_import_catenary')
require('test_import_entrance')
require('test_import_milestone')
require('test_import_platform')
require('test_import_poi')
require('test_import_railway_line')
require('test_import_route')
require('test_import_stop_position')
require('test_import_stop_area')
require('test_import_station')
require('test_import_switch')
require('test_import_turntable')

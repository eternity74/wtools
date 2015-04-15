#!/usr/bin/env python
import sys
import subprocess
import urlparse

if len(sys.argv) < 2:
    print "result.py filename.pcap"
    sys.exit(0)

filename = sys.argv[1]

throttle = 0
print "%-30s %-20s %-20s" % ( "TestName", "raw_score","throttle" )
for l in subprocess.check_output(["python", "parse_pcap.py", filename,"-u","set_throttle|results_handler","-vv"]).split():
    if "&m=" in l:
        result = urlparse.parse_qs(l)
#        print "------------------------------------------------------------------------------"
        throttle = result['m'][0]
    if 'test_name' in l:
        result = urlparse.parse_qs(l)
        print "%-30s %-20s %-20s" % ( result['test_name'][0],result['raw_score'][0],throttle )
#        print "------------------------------------------------------------------------------"

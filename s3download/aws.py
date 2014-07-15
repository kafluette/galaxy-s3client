#!/usr/bin/env python
import sys
import os
from subprocess import Popen, PIPE

print os.environ

CUR_DIR = os.path.dirname(os.path.realpath(__file__))

# get command line args
accesskey = sys.argv[1]
secretkey = sys.argv[2]
bucket = sys.argv[3]
remotefile = sys.argv[4]
localfile = sys.argv[5]
ud = sys.argv[6]

os.environ['AWS_ACCESS_KEY_ID'] = accesskey
os.environ['AWS_SECRET_KEY'] = secretkey

if localfile == '-':
	localfile = 's3client_download'

# build up the arguments
args = ['{}/aws.pl'.format(CUR_DIR),'--insecure-aws']
if ud == 'u':
	args.append('put')
else:
	args.append('get')
args += ['{}/{}'.format(bucket,remotefile),localfile]

# execute the perl script
print args
awspl = Popen(args,stdout=PIPE,stderr=PIPE)
stdout,stderr = awspl.communicate()
output = stdout.read()
error = stderr.read()

# redirect perl script's output
if len(output.strip()) == 0:
	# assume success
	pass
else:
	# we had an error
	sys.stdout.write(output)
	sys.stderr.write(error)

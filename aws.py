#!/usr/bin/env python
import sys
import hashlib
import os
import shutil
from subprocess import Popen, PIPE

TMP_DIR = '/mnt/disk1/tmp'

# get command line args
accesskey = sys.argv[1]
secretkey = sys.argv[2]
bucket = sys.argv[3]
remotefile = sys.argv[4]
localfile = sys.argv[5]
ud = sys.argv[6]
useremail = sys.argv[7]

# create the temporary folder
useremailhash = hashlib.md5(useremail).hexdigest()
os.environ['USEREMAILHASH'] = useremailhash
working_dir = os.path.join(TMP_DIR,useremailhash)
os.mkdir(working_dir)

# put the aws access key and secret in a temp file
aws_secrets_file = os.path.join(working_dir,'aws-secrets')
with open(aws_secrets_file,'wb') as handle:
	handle.write("{}\n{}".format(accesskey,secretkey))
os.environ['AWS_SECRETS_LOCATION'] = aws_secrets_file

# build up the arguments
args = ['aws.pl','--insecure-aws',accesskey,secretkey]
if ud == 'u':
	args.append('put')
else:
	args.append('get')
args += ['{}/{}'.format(bucket,remotefile),localfile]

# execute the perl script
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

# cleanup the temporary folder
shutil.rmtree(working_dir)

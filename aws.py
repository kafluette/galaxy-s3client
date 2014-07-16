#!/usr/bin/env python
import sys
import os
from subprocess import Popen, PIPE

CUR_DIR = os.path.dirname(os.path.realpath(__file__))

accesskey = sys.argv[1]
secretkey = sys.argv[2]
bucket = sys.argv[3]
remotefile = sys.argv[4]
localfile = sys.argv[5]
ud = sys.argv[6]

os.environ['EC2_ACCESS_KEY'] = accesskey
os.environ['EC2_SECRET_KEY'] = secretkey

args = ['{}/aws.pl'.format(CUR_DIR),'--insecure-aws']
if ud == 'u':
	args.append('put')
else:
	args.append('get')
args += ['{}/{}'.format(bucket,remotefile),localfile]

awspl = Popen(args,stdout=PIPE,stderr=PIPE)
stdout,stderr = awspl.communicate()

sys.stdout.write(stdout)
sys.stderr.write(stderr)

sys.exit(len(stderr.strip()))

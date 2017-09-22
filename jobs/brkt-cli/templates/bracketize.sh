#!/bin/bash -e

echo "Starting Bracketizing"

export AWS_REGION=<%= p('aws_region') %>
export STEMCELL_URL=<%= p('stemcell_url') %>
export MGMT_URL=<%= p('mgmt_url') %>
export SERVICE_DOMAIN=<%= p('service_domain') %>
export EMAIL=<%= p('email') %>
export PASSWORD=<%= p('password') %>
export AWS_ACCESS_KEY_ID=<%= p('aws_access_key_id') %>
export AWS_SECRET_ACCESS_KEY=<%= p('aws_secret_access_key') %>
export BUCKET_NAME=<%= p('bucket_name') %>
export OPS_MANAGER=<%= p('ops_manager') %>
export UAAC_TOKEN==<%= p('uaac_token') %>

source /var/vcap/packages/python-2.7/bosh/runtime.env
pip install brkt-cli
pip install awscli
FILENAME=`echo ${STEMCELL_URL} | cut -f5 -d'/'`
rm -rf /tmp/stemcell ${FILENAME}
wget $STEMCELL_URL
mkdir -p /tmp/stemcell
tar zxvf ${FILENAME} -C /tmp/stemcell
ami_id=`cat /tmp/stemcell/stemcell.MF | grep ${AWS_REGION} | awk '{print $2}'`
echo "Encrypting base AMI: ${ami_id}"
export BRKT_API_TOKEN=`brkt auth --root-url ${MGMT_URL} --email $EMAIL --password $PASSWORD`
brkt aws encrypt --region ${AWS_REGION} --service-domain ${SERVICE_DOMAIN} ${ami_id} | tee /tmp/encrypt.log
if [ `echo $?` -ne 0 ]; then
	echo "Bracket encryption failed. Please check encryption logs at /tmp/encrypt.log"
else
	output_ami=`tail -1 /tmp/encrypt.log | awk '{print $1}'`
	#sed -i "s/$ami_id/$output_ami/" /tmp/stemcell/stemcell.MF
	pdir=`pwd`
	pushd /tmp/stemcell
	tar czf ${pdir}/${FILENAME} `ls`
	popd
	echo "Uploading encrypted stemcell file: $pdir/${FILENAME} to bucket ${BUCKET_NAME}"
	aws s3 --region ${AWS_REGION} cp $pdir/${FILENAME} s3://${BUCKET_NAME}
	if [ "x${OPS_MANAGER}" != "x"  -a "x${UAAC_TOKEN}" != "x" ]; then
		echo "Uploading stemcell of Ops Manager at ${OPS_MANAGER}"
		curl -vk "https://${OPS_MANAGER}/api/v0/stemcells" \
		    -X POST -H "Authorization: Bearer ${UAAC_TOKEN}" \
		    -F "stemcell[file]=@${pdir}/${FILENAME}"
		if [ `echo $?` -eq 0 ]; then
			echo "Stemcell uploaded to Ops Manage successfully!"
		else
			echo "Failed to upload stemcell file to Ops Manager"
		fi
	fi
fi
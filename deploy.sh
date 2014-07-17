#!/bin/bash
echo "Cleaning up from previous deploy ..."
rm -rf out/deploy >/dev/null 2>&1
mkdir -p out/deploy

echo "Setting java home ..."
if [[ "$(hostname)" -eq "freyja" ]]; then
  echo "jdk.home.1.7=/usr/lib/jvm/java-7-oracle" > build.properties
else
  echo "jdk.home.1.7=/usr/lib/jvm/java-7-openjdk-amd64" > build.properties
fi

echo "Assuring libraries are present ..."

pushd . >/dev/null 2>&1
cd ..

if [ ! -d 'lib' ]; then
  echo "Missing libraries directory in parent directory. Creating ..."
  mkdir -p 'lib'
fi

cd lib

if [ ! -d "aws-java-sdk-1.8.5" ]; then
  echo "Missing AWS Java SDK in libraries. Getting ..."
  wget -q "http://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip" || (echo "Download failed." ; exit 4 )
  unzip -qq aws-java-sdk.zip
  rm aws-java-sdk.zip
  if [ ! -d "aws-java-sdk-1.8.5" ]; then
    echo "The wrong version of the SDK was downloaded. We want 1.8.5"
    exit 5
  fi
fi

popd >/dev/null 2>&1

echo "Building JAR ..."
ant || (echo "Build failed." ; exit 3)

echo "Copying over required files ..."
cp s3upload.xml s3download.xml out/deploy
cp out/artifacts/galaxy_s3client_jar/galaxy-s3client.jar out/deploy

echo "Cleaning up"
rm build.properties

echo "Move the out/deploy folder to tools/s3client in Galaxy and restart galaxy to deploy."


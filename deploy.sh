#!/bin/bash

echo "Checking for JDK ..."
if [ -z "$(which javac)" ]; then
  echo "No JDK found in your PATH."
  exit 9
else
  echo "Found JDK with javac at $(which javac)"
fi

echo "Cleaning up from previous deploy ..."
rm -rf out/deploy >/dev/null 2>&1
mkdir -p out/deploy

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

if [[ "$(hostname)" -eq "freyja" ]]; then
  echo "This script is running on freyja, attempting deploy ..."
  sudo cp out/deploy/* /shared/c2g2/galaxy-dist/tools/s3client/
  sudo chown -R galaxy:galaxy /shared/c2g2/galaxy-dist/tools/s3client
  sudo chmod -R 755 /shared/c2g2/galaxy-dist/tools/s3client

  echo "If a change was made to the XML files, you must restart Galaxy."
  echo "Changes to the JAR only do not require a restart."
  echo -n "Restart galaxy using /home/fluetteka/bin/restart-galaxy.sh? (y/n)"
  read cont

  if [[ "$cont" -eq "y" ]]; then
    echo "Restarting galaxy ..."
    /home/fluetteka/bin/restart-galaxy.sh
  else
    echo "Not restarting galaxy. You must do so manually."
  fi

  echo "Cleaning up deployment folder ..."
  rm -rf out/deploy

  echo -n "Remove artifacts? (y/n) "
  read remove_artifacts
  if [[ "$remove_artifts" -eq "y" ]]; then
    echo "Removing artifacts ..."
    rm -rf out/artifacts
  else
    echo "Leaving artifacts intact at out/artifacts."
  fi
else
  echo "This script is not running on freyja. You must manually deploy the new build."
  echo "Copy the contents of out/deploy to the tools/s3client folder in galaxy-dist, then restart galaxy if any changes were made to the XML."
fi


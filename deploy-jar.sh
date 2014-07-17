#!/bin/bash

echo "Checking for JDK ..."
if [ -z "$(which javac)" ]; then
  echo "No JDK found in your PATH."
  exit 9
else
  echo "Found JDK with javac at $(which javac)"
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

echo "Building JAR ... "
ant
if [[ $? -ne 0 ]]; then
  echo "Build failed."
  exit 11
else
    echo "New JAR built, located at out/artifacts/galaxy_s3client_jar/galaxy-s3client.jar"
fi

echo "If a change was made to the XML files, you must restart Galaxy."
echo "Changes to the JAR (or bash script) do not require a restart."

if [[ "$(hostname)" -eq "freyja" ]]; then
    echo -n "This script is running on freyja. Do you want to copy over the jar? (y/n)  "
    read should_copy
    if [[ "$should_copy" -eq "y" ]]; then
        echo -n "Copying JAR and fixing permissions ... "
        sudo cp out/artifacts/galaxy_s3client_jar/galaxy-s3client.jar /shared/c2g2/galaxy-dist/tools/s3client/
        sudo chown -R galaxy:galaxy /shared/c2g2/galaxy-dist/tools/s3client
        sudo chmod -R 755 /shared/c2g2/galaxy-dist/tools/s3client
        echo "Done."
    else
        echo "Not attempting deployment. To deploy the new JAR, copy it into the galaxy folder and assure good permissions."
    fi
else
    echo -n "This script is not running on freyja. Attempt to deploy the JAR? "
    read should_deploy
    if [[ "$should_deploy" -eq "y" ]]; then
        echo "Attempting naive remote deployment ... "
        scp out/artifacts/galaxy_s3client_jar/galaxy-s3client.jar freyja:
        ssh -t freyja 'sudo mv galaxy-s3client.jar /shared/c2g2/galaxy-dist/tools/s3client/'
        ssh -t freyja 'sudo chown -R galaxy:galaxy /shared/c2g2/galaxy-dist/tools/s3client'
        ssh -t freyja 'sudo chmod -R 755 /shared/c2g2/galaxy-dist/tools/s3client'
        echo "Deployed new JAR and fixed permissions."
    else
        echo "Not attempting deployment. Manually deploy the JAR file if needed."
    fi
fi

echo -n "Remove artifacts? (y/n) "
read remove_artifacts
if [[ "$remove_artifts" -eq "y" ]]; then
    echo -n "Removing artifacts ... "
    rm -rf out/artifacts
    echo "Done."
else
    echo "Leaving artifacts intact at out/artifacts."
fi

echo "Note: this script only handled the JAR file. Any handling of XML files or the bash script must be done manually."


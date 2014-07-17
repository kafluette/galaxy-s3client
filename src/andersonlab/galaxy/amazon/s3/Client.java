package andersonlab.galaxy.amazon.s3;

import com.amazonaws.AmazonClientException;
import com.amazonaws.auth.AWSCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.auth.EnvironmentVariableCredentialsProvider;
import com.amazonaws.internal.StaticCredentialsProvider;
import com.amazonaws.services.s3.transfer.Download;
import com.amazonaws.services.s3.transfer.TransferManager;
import com.amazonaws.services.s3.transfer.Upload;

import java.io.File;

public class Client {
    public static void main(String[] args) {
        if (args.length != 6 && args.length != 4) {
            System.err.println("Command line args: u/d bucket remote_file local_file [access_key secret_key]");
            System.err.println("Where access_key and secret_key are optional. The environment variables");
            System.err.println("AWS_ACCESS_KEY and AWS_SECRET_ACCESS_KEY are used if you do not provide them on the");
            System.err.println("command line.");
            System.exit(3);
        }

        String mode = args[0];
        String bucket = args[1];
        String remote_filename = args[2];
        String local_filename = args[3];

        AWSCredentialsProvider credentialsProvider;
        if (args.length == 6) {
            String access_key = args[4];
            String secret_key = args[5];
            credentialsProvider = new StaticCredentialsProvider(new BasicAWSCredentials(access_key,secret_key));
        } else {
            credentialsProvider = new EnvironmentVariableCredentialsProvider();
        }

        TransferManager tm = new TransferManager(credentialsProvider);

        if (mode.equals("u")) {
            System.out.printf("Uploading file \"%s\" to \"%s\" in bucket \"%s\"\n",local_filename,remote_filename,bucket);
            File local_file = new File(local_filename);
            Upload upload = tm.upload(bucket,remote_filename,local_file);

            try {
                upload.waitForCompletion();
                System.out.println("Upload complete.");
            } catch (AmazonClientException ex1) {
                System.err.println("Unable to upload file, upload was aborted.");
                ex1.printStackTrace();
            } catch (InterruptedException ex2) {
                System.err.println("Unable to upload file, upload was interrupted.");
                ex2.printStackTrace();
            }
        } else {
            System.out.printf("Download file \"%s\" from bucket \"%s\" to file \"%s\"\n",remote_filename,bucket,local_filename);
            File local_file = new File(local_filename);
            Download download = tm.download(bucket,remote_filename,local_file);

            try {
                download.waitForCompletion();
                System.out.println("Download complete.");
            } catch (AmazonClientException ex1) {
                System.err.println("Download to upload file, download was aborted.");
                ex1.printStackTrace();
            } catch (InterruptedException ex2) {
                System.err.println("Download to upload file, download was interrupted.");
                ex2.printStackTrace();
            }
        }

        tm.shutdownNow();
    }
}

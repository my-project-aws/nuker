package main

import (
	"archive/tar"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"

	"github.com/aws/aws-lambda-go/lambda"
)

const (
	confFile = "nuke-config.yml"
	awsNuke  = "/tmp/aws-nuke-v2.19.0-linux-amd64"
)

func check(e error) {
	if e != nil {
		panic(e)
	}
}

func preAwsNuke() {
	log.Println("Creating zip to recieve the aws-nuke tar.gz")
	out, err := os.Create("/tmp/aws-nuker.zip")
	defer out.Close()
	if err != nil {
		log.Fatalln(err)
	}

	log.Println("Downloading zip from aws-nuker github release")
	resp, err := http.Get("https://github.com/rebuy-de/aws-nuke/releases/download/v2.19.0/aws-nuke-v2.19.0-linux-amd64.tar.gz")
	if err != nil {
		log.Fatalln(err)
	}
	defer resp.Body.Close()

	log.Println("Copy the zip in the zip file in tmp")
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		log.Fatalln(err)
	}
	r, err := os.Open("/tmp/aws-nuker.zip")
	if err != nil {
		log.Fatalln(err.Error())
	}
	ExtractTarGz(r)
}

func ExtractTarGz(gzipStream io.Reader) {
	log.Println("Reading the Zip file and preparing to extract the binary of aws-nuke")
	uncompressedStream, err := gzip.NewReader(gzipStream)
	if err != nil {
		log.Fatal("ExtractTarGz: NewReader failed")
	}

	tarReader := tar.NewReader(uncompressedStream)

	for true {
		header, err := tarReader.Next()

		if err == io.EOF {
			break
		}

		if err != nil {
			log.Fatalf("ExtractTarGz: Next() failed: %s", err.Error())
		}

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.Mkdir("/tmp/"+header.Name, 0755); err != nil {
				log.Fatalf("ExtractTarGz: Mkdir() failed: %s", err.Error())
			}
		case tar.TypeReg:
			outFile, err := os.Create("/tmp/" + header.Name)
			err = os.Chmod(outFile.Name(), 0755)
			if err != nil {
				log.Fatalf("ExtractTarGz: Create() failed: %s", err.Error())
			}
			defer outFile.Close()
			if _, err := io.Copy(outFile, tarReader); err != nil {
				log.Fatalf("ExtractTarGz: Copy() failed: %s", err.Error())
			}
		default:
			log.Fatalf(
				"ExtractTarGz: uknown type: %v in %s",
				header.Typeflag,
				header.Name)
		}
	}
}

func HandleRequest(ctx context.Context) (string, error) {

	preAwsNuke()
	fmt.Println("We will be running aws-nuke")
	data, err := os.ReadFile(confFile)
	if err != nil {
		log.Fatalln("Can not read file", confFile, err)

	}

	fmt.Println("Content of aws-nuke configuration file is:")
	fmt.Println(string(data))

	awsNukeCmd := exec.Command(awsNuke, "--force", "--force-sleep", "5", "--no-dry-run", "-c", confFile)
	awsNukeCmd.Stderr = os.Stderr
	awsNukeCmd.Stdin = os.Stdin
	awsNukeCmd.Stdout = os.Stdout
	check(awsNukeCmd.Run())

	return "", nil
}

func main() {
	lambda.Start(HandleRequest)
}

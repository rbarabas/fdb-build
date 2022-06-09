#/usr/bin/env bash
OS=$(uname -s)
ARCH=$(uname -m)
URL=https://github.com/krallin/tini/releases/download/v0.19.0/tini

case "${ARCH}" in
	amd64|x86_64)
		CPU=amd64
		;;
	arm64|aarch64)
		CPU=arm64
		;;
	*)
		echo "Architecture not supported"
		exit 1
esac

case "${CPU}" in
	amd64)
		SHA256=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c
		;;
	arm64)
		SHA256=07952557df20bfd2a95f9bef198b445e006171969499a1d361bd9e6f8e5e0e81
		;;
esac

curl -sLo tini ${URL}-${CPU}
echo "${SHA256}  tini" > tini-sha256.txt
sha256sum --quiet -c tini-sha256.txt
chmod +x ./tini 
mv ./tini /usr/bin/
rm -rf /tmp/*

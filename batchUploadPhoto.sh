#!/bin/bash

entityFileName=currentEntityData.json
token=36E9543B73A1AEC6617EFA117933CB04

if [ $(dpkg-query -W -f='${Status}' tmux 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
	  apt-get install jq;
fi

# Get the entity list of import data
curl 'https://mms.hktv.com.hk/mms/productTempController/seachEntityListAndInit' -H 'Origin: https://mms.hktv.com.hk' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7,zh-CN;q=0.6' -H 'User-Agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.81 Mobile Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -H 'Referer: https://mms.hktv.com.hk/mms/' -H 'Cookie: JSESSIONID='$token -H 'Connection: keep-alive' --data-binary '{"contractId":14261,"merchantId":16169,"uploadBy":24575,"storeList":"12140;","actions":["EDIT","ADD"]}' --compressed | jq '.[].tmpId' > input_tmp_ids

while IFS="" read -r p || [ -n "$p" ]
do
  	printf 'Processing tmpId: %s ...\n' "$p"
   	# Get entity
	curl 'https://mms.hktv.com.hk/mms/productTempController/viewEntityDetail' -H 'Origin: https://mms.hktv.com.hk' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-HK,zh;q=0.9,en-US;q=0.8,en;q=0.7' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -H 'Referer: https://mms.hktv.com.hk/mms/' -H 'Cookie: JSESSIONID='$token -H 'Connection: keep-alive' --data-binary '{"tmpId":'$p'}' --compressed > $entityFileName


	# Manipluate the photo ID
	tmp=$(mktemp)
	# jq '.imagesList=["Put the image here"]' $entityFileName > "$tmp" && mv "$tmp" $entityFileName

	# Manipluate the fine print En for testing
	jq '.finePrintEn="Data Imported by Just Move"' $entityFileName > "$tmp" && mv "$tmp" $entityFileName
	jq '.id=null' $entityFileName > "$tmp" && mv "$tmp" $entityFileName
	jq '.deliveryMethod="merchant-delivery"' $entityFileName > "$tmp" && mv "$tmp" $entityFileName


	# cat $entityFileName | grep imagesList

	# Save the entity
	curl 'https://mms.hktv.com.hk/mms/productController/saveEntity' -H 'Origin: https://mms.hktv.com.hk' -H 'Accept-Encoding: gzip, deflate, br' -H 'Accept-Language: zh-HK,zh;q=0.9,en-US;q=0.8,en;q=0.7' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/66.0.3359.181 Safari/537.36' -H 'Content-Type: application/json;charset=UTF-8' -H 'Accept: application/json, text/plain, */*' -H 'Referer: https://mms.hktv.com.hk/mms/' -H 'Cookie: JSESSIONID='$token -H 'Connection: keep-alive' --data-binary "@"$entityFileName --compressed > currentResult.json

	cat currentResult.json

	importedSKU=$(jq '.skuCode' $entityFileName)

	echo $p":"$importedSKU >> result.log

	echo "Finished imported: "$importedSKU
done < input_tmp_ids
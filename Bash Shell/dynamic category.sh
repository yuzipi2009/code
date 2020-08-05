#!/bin/bash

# run as yuxiao
# category.sh stage or
# category.sh preprod or
# category.sh prod

env=$1

category=(
Games.BXb2f5RuNEXi6oT_Rp5E
Entertainment.WstqkAR9EJe4zcT5zNfW
Social.LHUie_MdnNSRwx5TTo-g
Shopping.zVgkJv-e-Tn70LcC4ERj
News.IzDDSpwFUYK1tAEDoBSq
Utilities.gNejh5rwrBkmB3ej-gVB
Lifestyle.BHCubrVVAHIvHaqLJhhq
Health.HxBj3vYcZTQc4mQbqPpV
Sports.xJWF098bNyu8jN3r6_I-
Books.1yrXM4DFrOFYekiy9X-Z
)

if [ "$1" != "stage" ] && [ "$1" != "preprod" ] && [ "$1" != "prod" ];then
    echo "the first parameter should in 'stage,preprod,or prod'"
    exit 1
fi

if [ ! -d json ] || [ ! -d locales ];then
    echo "didn't find json or locales dir, Aborting"
    exit 2
fi

if [ ! -f ./bin/test_hawk ];then
    echo "didn't find test_hawk file, Aborting"
    exit 3
fi

# refresh access token
#./bin/test_hawk -H 'Content-Type:application/json' -d @jwt/test_login.json POST https://api.${env}.kaiostech.com/v3.0/tokens >jwt/{env}_token.json
[ $? -ne 0 ] && {
echo "refresh token failed, Aborting"
exit
}


# loop fetch all categories to json files
for category in ${category[*]};do
     name=`echo ${category}|awk -F. '{print $1}'`
     id=`echo ${category}|awk -F. '{print $2}'`
     ./bin/test_hawk -c jwt/{env}_token.json -H 'User-Agent: KaiOS/2.5' -H 'Kai-Device-Info: imei=234234234234234, curef=TEST1' -H 'Kai-API-Version: 3.0'  GET https://api.${env}.kaiostech.com/v3.0/categories/${id} > json/${name}.json 2>/dev/null
    [ $? -ne 0 ] && {
    echo "Get failed, Aborting"
    exit
}
    echo "saved ${name} to json/${name}.json"
done

# locales files in locales dir, replace the locales part for each json file
for file in `ls locales`;do
    #the list of ${locale} should the same as the list of ${name}, just different sequence
    locale=`echo ${file}|awk -F. '{print $1}'`
    body=`cat locales/${file}`
    sed -i "s#:{\S\+\"}#:${body}#g" json/${locale}.json
    [ $? -ne 0 ] && {
    echo "sed failed, Aborting"
    exit 4
}
    echo "modified ${locale}.json successfully"
done

# modify Books.json again, because there is a & in Books.json, need to escape fron it
sed -i 's#:{\"en-US\":\"Books/Reference\"}#\&#g' json/Books.json
check=`grep '&' json/Books.json`
if [ -n "${check}" ] && echo "Modified Books json successfully"||echo "Failed for modify Books.json"

# run put api to update category object
for category in ${category[*]};do
    name=`echo ${category}|awk -F. '{print $1}'`
    id=`echo ${category}|awk -F. '{print $2}'`
    echo "name is ${name}"
    echo "id is ${id}"
    continue
    #./bin/test_hawk -H 'Content-Type:application/json' -c ./jwt/${env}_token.json -d @./json/${name}.json PUT https://api.${env}.kaiostech.com/v3.0/categories/${id}
    [ $? -ne 0 ] && {
    echo "PUT failed, Aborting"
    exit
}
    echo "Update ${name} successfully"
done


rm -rf test-hawk.log.*
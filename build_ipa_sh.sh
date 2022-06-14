
#使用方法
if [ ! -d ./IPADir ];
then
mkdir -p IPADir;
fi

#工程绝对路径
project_path=/Users/shark/Desktop/APP

echo "环境:"
read envir_desc

echo "更新内容:"
read update_desc

#工程名
project_name=APP
#scheme名
scheme_name=APP
product_name=APP

#打包模式 Debug/Release
development_mode=Release

#蒲公英参数
user_key=xxx
api_key=xxx

current_path=$(cd `dirname $0`; pwd)

#build文件夹路径
build_path=${current_path}/build

#plist文件所在路径
exportOptionsPlistPath=${current_path}/exportTest.plist

#导出.ipa文件所在路径
exportIpaPath=${current_path}/IPADir/${development_mode}


##json解析函数
function jsonParse() { # $1 $2  json lable

     JSON_CONTENT=$1
     KEY='"'$2'":'

     echo ${JSON_CONTENT} | awk -F  ${KEY}  '{print $2}' | awk -F '"' '{print $2}'
}

##删除斜杠'\'
function trimSlash() {
    TEXT=$1
    echo ${TEXT//'\'/''}
}


echo "第一步，进入项目工程文件"

cd $project_path

echo '正在清理工程'

xcodebuild \
clean -configuration ${development_mode} -quiet  || exit

echo '清理完成'

echo '正在编译工程:'${development_mode}

xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo '编译完成'

echo '开始ipa打包'

xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$product_name.ipa ]; then
echo 'ipa包已导出'

    echo '发布ipa包到 =============蒲公英平台============='
    RESPONSE=$(curl -F "file=@$exportIpaPath/$product_name.ipa" -F "uKey=${user_key}" -F "_api_key=${api_key}" -F "updateDescription=${update_desc}" https://www.pgyer.com/apiv2/app/upload)

    if [ $? -eq 0 ];then
    echo "=============提交蒲公英成功 ============="

    appQRCodeURL=$(trimSlash $(jsonParse "${RESPONSE}" "buildQRCodeURL"))
    appVersion=$(jsonParse "${RESPONSE}" "buildVersion")
    appBuildVersion=$(jsonParse "${RESPONSE}" "buildBuildVersion")

    #通知到钉钉群 将xxxxxxxx替换为真实access_token `title`需要包含关键词
    curl 'https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxx' \
        -H 'Content-Type: application/json' \
        -d '
    {
        "msgtype": "markdown",
        "markdown": {
            "title":"xxxx",
            "text":"![screenshot]('"$appQRCodeURL"')  \n  **版本:** '"$appVersion"' (build '"$appBuildVersion"')  \n  **环境:** '"$envir_desc"'  \n  **说明:** '"$update_desc"'"
        }
    }'
    else
    echo "=============提交蒲公英失败 ============="
    fi

#open $exportIpaPath
else
echo 'ipa包导出失败 '
fi
echo '打包ipa完成  '

exit 0




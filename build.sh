#!/bin/bash

PLATFORMPATH="/Applications/Xcode.app/Contents/Developer/Platforms"
TOOLSPATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin"
export IPHONEOS_DEPLOYMENT_TARGET="6.0"
pwd=`pwd`

findLatestSDKVersion()
{
    sdks=`ls $PLATFORMPATH/$1.platform/Developer/SDKs`
    arr=()
    for sdk in $sdks
    do
       arr[${#arr[@]}]=$sdk
    done

    # Last item will be the current SDK, since it is alpha ordered
    count=${#arr[@]}
    if [ $count -gt 0 ]; then
       sdk=${arr[$count-1]:${#1}}
       num=`expr ${#sdk}-4`
       SDKVERSION=${sdk:0:$num}
    else
       SDKVERSION="8.0"
    fi
}

buildit()
{
    target=$1
    hosttarget=$1
    platform=$2

    if [[ $hosttarget == "x86_64" ]]; then
        hostarget="i386"
    elif [[ $hosttarget == "arm64" ]]; then
        hosttarget="arm"
    fi

    export CC="$(xcrun -sdk iphoneos -find clang)"
    export CPP="$CC -E"
    export CFLAGS="-fembed-bitcode -arch ${target} -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk -miphoneos-version-min=$SDKVERSION"
    export AR=$(xcrun -sdk iphoneos -find ar)
    export RANLIB=$(xcrun -sdk iphoneos -find ranlib)
    export CPPFLAGS="-arch ${target}  -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk -miphoneos-version-min=$SDKVERSION"
    export LDFLAGS="-arch ${target} -isysroot $PLATFORMPATH/$platform.platform/Developer/SDKs/$platform$SDKVERSION.sdk"

    mkdir -p $pwd/build/$target

     ./configure --prefix="$pwd/build/$target" --host=$hosttarget-apple-darwin

    make clean
    make -j8
    make install
}

findLatestSDKVersion iPhoneOS

buildit armv7 iPhoneOS
buildit armv7s iPhoneOS
buildit arm64 iPhoneOS
buildit i386 iPhoneSimulator
buildit x86_64 iPhoneSimulator

mkdir -p $pwd/output/lib/

cp -R $pwd/build/armv7/include $pwd/output/

LIPO=$(xcrun -sdk iphoneos -find lipo)
$LIPO -create $pwd/build/armv7/lib/libsrtp2.a $pwd/build/armv7s/lib/libsrtp2.a $pwd/build/arm64/lib/libsrtp2.a $pwd/build/x86_64/lib/libsrtp2.a $pwd/build/i386/lib/libsrtp2.a -output $pwd/output/lib/libsrtp2.a

rm -rf $pwd/build
#Author : Bestcoderg
#Date : 2021/04/21
#Usage : Build Ro project,put this script in the same directory as roserver

#!/bin/bash

RO_DIR=$(pwd)
MAKE_NUM=64

if [ $# -eq 1 ]
then
    MAKE_NUM=$1
fi

#Building rogamelibs ...
pushd .
echo -e "\033[44;37;5m Building rogamelibs ... \033[0m"
cd $RO_DIR/rogamelibs/table/buildtool/
sed -i "s/cmake -D/cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -D/g" build_linux.sh
sh build_linux.sh
sed -i "s/ -DCMAKE_EXPORT_COMPILE_COMMANDS=1//g" build_linux.sh

cd $RO_DIR/rogamelibs/buildtool/
sed -i "s/cmake -D/cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -D/g" build_linux.sh
sh build_linux.sh
sed -i "s/ -DCMAKE_EXPORT_COMPILE_COMMANDS=1//g" build_linux.sh

cat $RO_DIR/rogamelibs/table/buildtool/build_linux/compile_commands.json >> ./build_linux/compile_commands.json
cp ./build_linux/compile_commands.json $RO_DIR/rogamelibs/  
sed -i "s/\]\[/\,/g" $RO_DIR/rogamelibs/compile_commands.json
popd

#Relink soft_linker
ln -sf $RO_DIR/rogamelibs $RO_DIR/roserver/rogamelibs
ln -sf $RO_DIR/rogamelibs/buildtool/Server/lib/librogamelibs.a $RO_DIR/roserver/lib/librogamelibs.a
#ln -sf $RO_DIR/rogamelibs/buildtool/Server/lib/librogamelibs_release.a $RO_DIR/roserverlib/librogamelibs_release.a
ln -sf $RO_DIR/rogamelibs/table/buildtool/Server/lib/libconfiglib.a lib/libconfiglib.a

#Building roserver ...
pushd .
echo -e "\033[44;37;5m Building roserver ... \033[0m"
cd $RO_DIR/roserver/
#Building cmake files
sed -i "s/DASAN=Off/DASAN=On/g" create_cmake.sh
sed -i "s/cmake -D/cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -D/g" create_cmake.sh
sh create_cmake.sh $RO_DIR/config
sed -i "s/ -DCMAKE_EXPORT_COMPILE_COMMANDS=1//g" create_cmake.sh
sed -i "s/DASAN=On/DASAN=Off/g" create_cmake.sh

cd ./Build/Debug/protocol/pb/ && make -j64
cd ../..
filename=("gateserver" "controlserver" "dbserver" "tradeserver" "battleserver" 
    "audioserver" "masterserver" "gameserver") #"loginserver" "idipserver")
serv_num=${#filename[@]}
maked_serv=0
failed_serv=()
for serv in ${filename[@]}
do
    cd $serv
    make -j${MAKE_NUM}
    if [ $? -eq 0 ];then
        echo -e "\033[44;37;5m Builded ${serv} \033[0m"
        maked_serv=$(($maked_serv+1))
    else
        failed_serv[${#failed_serv[@]}]=$serv
        echo -e "\033[46;31;5m Builded ${serv} failed! \033[0m"
    fi
    cd ..
done

cp compile_commands.json ../..

cat $RO_DIR/rogamelibs/compile_commands.json >> $RO_DIR/roserver/compile_commands.json
sed -i "s/\]\[/\,/g" $RO_DIR/roserver/compile_commands.json

popd

echo -e "\033[43;35;5m Target servers ${serv_num} . \033[0m"
echo -e "\033[43;35;5m Builded servers ${maked_serv} . \033[0m"
if [ ${#failed_serv[@]} -ne 0 ]; then
    echo -e "\033[46;31;5m Failed servers: ${failed_serv[@]} . \033[0m"
fi
echo -e "\033[43;35;5m Finish Build! \033[0m"

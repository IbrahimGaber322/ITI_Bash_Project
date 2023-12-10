#!/bin/bash
source dbfunctions.bash
source tablefunctions.bash
shopt -s extglob
currentDirectory=$(pwd)
check=0
connectedDB=0
if [ -d "${currentDirectory}/database" ]; then
    echo "Folder exists"
    check=1
else
    echo "Folder does not exist"
    read -p "Would you like to create one? (y for yes, n for no): " answer

    if [ "$answer" == "y" ]; then
        mkdir "${currentDirectory}/database"
        echo "Folder created"
        check=1
    else
        echo "Exiting script"
        exit 1
    fi
fi

if [ "$check" == "1" ]; then
    currentDirectory = "${currentDirectory}"/database
    select choice in "Create new database" "List databases" "Drop database" "Connect to database"
    case $reply in 
    1)

    #create table
      createDB $currentDirectory
    ;;
    2)
    listDB $currentDirectory 
    ;;
    3)
    dropDB $currentDirectory
    ;;
    4)
    dbName=$(connectDB)
    [ $dbName != 0 ] &&  connectedDB="${currentDirectory}/${dbName}"    ;;
    esac
fi


echo "Welcome to DBMS"

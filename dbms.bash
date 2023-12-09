#!/bin/bash
shopt -s extglob
currentDirectory=$(pwd)
check=0

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
    DB = "${currentDirectory}"/database
    select choice in "Create new database" "List databases" "Drop database" "Connect to database"
    case $reply in 
    1)
      #createDb check if exists ---> create
      #f []
      # spaciial -numbers -spaces
      read -p "eneter database name" dirName

      if [[ "$dirName" = ~ [a-zA-Z0-9] ]];then
      echo "invalid name"
      else
      
     
      if [ -d $dirName  ]; then
      echo "DB already exists try a new name"
      else
      mkdir $dirName
      fi
      fi
      

    ;;
    2)
      #listDb
    ;;
    3)
      #dropDb
    ;;
    4)
      #connectDb
    ;;
    esac
fi

echo "Welcome to DBMS"

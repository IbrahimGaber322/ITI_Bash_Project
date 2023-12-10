#!/bin/bash

shopt -s extglob

function directoryExists() {
    if [ -d "$1" ]; then
        return 0  
    else
        return 1  
    fi
}


function createDB() {
     while true 
    do
    read -p "Enter database name: " input
    dirName="$1/${input}"
    if [[ "$dirName" =~ ^[a-zA-Z_][a-zA-Z0-9_]* ]]; then
        echo "Invalid name."
    else
        if directoryExists "$dirName"; then
            echo "Database already exists."
        elif [ $input = "exit" ]; then
            exit 0
        else
            mkdir "$dirName"
            echo "Database '$dirName' created successfully."
            break

        fi
    fi
    done
}
createDB ~
function listDB()
{
    `ls -d $1`
}

# function listDB()
# {
#     `ls -l | grep / `
# }

function connectDB()
{
    read -p "Enter Database Name:" name
    if [ $name -e];then
    echo $name
    else
    echo "Database Not found"
    error=0
    echo $error 
    fi
    
}


function dropDB()
{
        read -p "Enter Database Name:" name
    if [ $name -e];then
     read -p "Are you sure you want to delete $name ? y for yes, n for no" name 
      [ $name = "y" ] && `rm -r $1/$name ` 

    else
    echo "Database Not found"
    fi
}


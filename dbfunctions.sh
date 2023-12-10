#!/bin/bash

shopt -s extglob

function directoryExists() {
    if [ -d "$1" ]; then
        return 0  
    else
        return 1  
    fi
}

read -p "Enter database name: " dirName

if [[ ! "$dirName" =~ [a-zA-Z0-9] ]]; then
    echo "Invalid name."
else
    if directoryExists "$dirName"; then
        echo "Database already exists."
    else
        mkdir "$dirName"
        echo "Database '$dirName' created successfully."
    fi
fi

function createDb() {
    read -p "Enter database name: " dirName

    if [[ "$dirName" =~ [a-zA-Z0-9] ]]; then
        echo "Invalid name."
    else
        if directoryExists "$dirName"; then
            echo "Database already exists."
        else
            mkdir "$dirName"
            echo "Database '$dirName' created successfully."
        fi
    fi
}

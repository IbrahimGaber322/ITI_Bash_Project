#!/bin/bash

shopt -s extglob

function directoryExists() {
    [[ -d "$1" ]]
}

function createDB() {
    while true; do
        read -p "Enter database name: (type "cancel" to cancel)" input
        dirName="$1/${input}"
        if [ "$input" == "cancel" ];then
            break
        elif ! [[ "$input" =~ ^[a-zA-Z_][a-zA-Z0-9_]* ]]; then
            echo "Invalid name."
        elif directoryExists "$dirName"; then
            echo "Database already exists."
        elif [ "$input" = "exit" ]; then
            exit 0
        else
            mkdir "$dirName"
            echo "Database '$input' created successfully."
            break
        fi
    done
}

function listDB() {
    ls -l "$1" | awk '/^d/ {print $NF}'
}

function connectDB() {
    read -p "Enter Database Name: " name
    if directoryExists "$1/$name"; then
        echo "$name"
        return 0  # Success
    else
        echo "Database not found"
        return 1  # Failure
    fi
}

function dropDB() {
    read -p "Enter Database Name: " name
    if directoryExists "$1/$name"; then
        read -p "Are you sure you want to delete '$name'? (y for yes, n for no): " confirm
        if [ "$confirm" = "y" ]; then
            rm -r "$1/$name"
            echo "Database '$name' deleted successfully."
        else
            echo "Deletion canceled."
        fi
    else
        echo "Database not found."
    fi
}

# Example usage:
# createDB "~"
# listDB "~"
# dbName=$(connectDB "~")
# dropDB "~"

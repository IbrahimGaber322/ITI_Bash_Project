#!/bin/bash

#create table-->file for data(values) file for metadata(like keys "name or age or anthing this should be an input from user and also data type in or string or pk or not this depends on user choice")
#file of values should be like ali:22:test
#file of meta data should be name:age
#                             pk
#                             string:int 
#list table
#drop table
#insert into table
#select from table
#delete from table
#update table


shopt -s extglob

createTable() {
    read -p "Enter table name: " tableName

if [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_[:space:]]*$ ]]; then #table name validation
        echo "Invalid table name. Table names must start with a letter or underscore, followed by letters, numbers, or underscores."
        return
    fi

    tableDir="./$tableName"

    if [ -d "$tableDir" ]; then
        echo "Table '$tableName' already exists."
        return
    fi

    mkdir "$tableDir"

    # Metadata file
    metadataFile="$tableDir/metadata.txt"
    touch "$metadataFile"

    # Values file
    valuesFile="$tableDir/values.txt"
    touch "$valuesFile"

    read -p "Enter the number of columns: " numColumns

    declare -A primaryKeyValues

    for ((i = 1; i <= numColumns; i++)); do
        read -p "Enter column $i name: " colName
        read -p "Enter column $i data type: " colType

if [[ ! "$colType" =~ ^(int|string|bool)$ ]]; then
    echo "Invalid data type. Supported types: int, string, bool."
    return
fi

read -p "Is column $colName a primary key? (y/n): " isPK

if [ "$isPK" = "y" ]; then
    # validate pk
    read -p "Enter primary key value for $colName: " pkValue
    existingPKs=($(awk -F: -v colIndex=$(($i + 1)) '{print $colIndex}' "$metadataFile"))
    if [ -n "$(printf '%s\n' "${existingPKs[@]}" | grep -w "$pkValue")" ]; then
        echo "Primary key value must be unique. Value '$pkValue' is already taken for column '$colName'."
        return
    fi

    echo "$colName:$colType:$isPK:$pkValue" >>"$metadataFile"
    echo "$pkValue" >>"$valuesFile"  # Store primary key value in values file
else
    echo "$colName:$colType:$isPK" >>"$metadataFile"
    read -p "Enter value for $colName ($colType): " value
    echo "$value" >>"$valuesFile"  # Store value in values file
fi



        echo "$colName:$colType:$isPK" >>"$metadataFile"
         echo "$colName:$colType:$pkvalue" >>"$valuesFile"

    done

    echo "Table '$tableName' created successfully."
}



options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Quit")
select option in "${options[@]}"; do
    case $option in
        "Create Table")
            createTable
            ;;
        "List Tables")
            listTables
            ;;
        "Drop Table")
            dropTable
            ;;
        "Insert into Table")
            insertIntoTable
            ;;
        "Select From Table")
            selectFromTable
            ;;
        "Delete From Table")
            deleteFromTable
            ;;
        "Update Table")
            updateTable
            ;;
        "Quit")
            break
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done

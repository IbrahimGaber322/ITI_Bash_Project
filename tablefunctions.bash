#!/bin/bash

shopt -s extglob

createTable() {
    read -p "Enter table name: " tableName

    if [[ ! "$tableName" =~ ^[a-zA-Z_][a-zA-Z0-9_[:space:]]*$ ]]; then
        echo "Invalid table name. Table names must start with a letter or underscore, followed by letters, numbers, or underscores."
        return
    fi

    if [ -d "$1/$tableName" ]; then
        echo "Table '$tableName' already exists."
        return
    fi

    mkdir "$1/$tableName"
    if [ $? -ne 0 ]; then
        echo "Failed to create table '$tableName'."
        return
    fi
    tableDir="$1/$tableName"

    # Metadata file
    touch "$tableDir/metadata.txt"
    metadataFile="$tableDir/metadata.txt"

    # Values file
    touch "$tableDir/values.txt"
    valuesFile="$tableDir/values.txt"

    read -p "Enter the number of columns: " colNum
    
    hasPK=0

    for ((i = 1; i <= colNum; i++)); do
        read -p "Enter column $i name: " colName
        read -p "Enter column $i data type (int|string|bool): " colType

        if [[ ! "$colType" =~ ^(int|string|bool)$ ]]; then
            echo "Invalid data type. Supported types: int, string, bool."
            return
        fi

        isPK="n"
        ((hasPK == 0)) && read -p "Is column $colName a primary key? (y/n): " isPK

        if [ "$isPK" = "y" ]; then
            hasPK=1
        fi
        echo "$colName:$colType:$isPK" >>"$metadataFile"
    done

    echo "Table '$tableName' created successfully."
}

listTables() {
    tables=$(find "$1" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    echo "Tables: $tables"
}

dropTable() {
    read -p "Enter table name to drop: " tableName
    if [ -d "$1/$tableName" ]; then
        read -p "Are you sure you want to drop table '$tableName'? (y/n): " confirm
        if [ "$confirm" = "y" ]; then
            rm -r "$1/$tableName"
            echo "Table '$tableName' dropped successfully."
        else
            echo "Drop operation canceled."
        fi
    else
        echo "Table '$tableName' does not exist."
    fi
}

# Implement other functions (insertIntoTable, selectFromTable, deleteFromTable, updateTable) based on your requirements.

# Example usage:
# options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Quit")
# select option in "${options[@]}"; do
#     case $option in
#         "Create Table")
#             createTable
#             ;;
#         "List Tables")
#             listTables
#             ;;
#         "Drop Table")
#             dropTable
#             ;;
#         "Insert into Table")
#             insertIntoTable
#             ;;
#         "Select From Table")
#             selectFromTable
#             ;;
#         "Delete From Table")
#             deleteFromTable
#             ;;
#         "Update Table")
#             updateTable
#             ;;
#         "Quit")
#             break
#             ;;
#         *)
#             echo "Invalid option."
#             ;;
#     esac
# done


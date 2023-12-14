#!/bin/bash

shopt -s extglob

# Function to check if a value exists in an array
function value_exists() {
    local value="$1"
    shift
    local array=("$@")

    for item in "${array[@]}"; do
        if [ "$item" == "$value" ]; then
            return 0  # Value exists in the array
        fi
    done

    return 1  # Value does not exist in the array
}

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

    resultString="${tableName// /_}"
    mkdir "$1/$resultString"

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

# Function to insert data into a table
function insertIntoTable() {
    # Prompt for table name
    read -p "Enter table name to insert into: " tableName
    tableDir="$1/$tableName"

    # Check if the table directory exists
    if [ ! -d "$tableDir" ]; then
        echo "Table '$tableName' does not exist."
        return
    fi

    metadataFile="$tableDir/metadata.txt"
    valuesFile="$tableDir/values.txt"

    # Check if the table has columns
    if [ ! -s "$metadataFile" ]; then
        echo "Table '$tableName' has no columns defined."
        return
    fi

    # Get the number of lines in metadata file
    linesNum=$(wc -l < "$metadataFile")

    # Primary values array
    # Assuming $inputString contains the input data
    primArr=()

    while IFS=':' read -r firstValue _; do
        primArr+=("$firstValue")
    done < "$valuesFile"

    echo $primArr
    inputString=""
    # Loop through each column in metadata
    for ((i = 1; i <= linesNum; i++)); do
        # Extract column information
        line=$(sed -n "$i p" "$metadataFile")
        IFS=':' read -ra arr <<< "$line"
        valueName=${arr[0]}
        valueType=${arr[1]}  # Fix the array index for valueType
        isPrim=${arr[2]}     # Fix the array index for isPrim
        inputValue=""

        # Prompt user for input based on column type
        while true; do
            if [[ $isPrim == "y" ]]; then
                read -p "Enter value of $valueName:$valueType (Primary Key, type 'cancel' to cancel): " inputValue
            elif [[ $isPrim == "n" ]]; then
                read -p "Enter value of $valueName:$valueType (press Enter for nullable or type 'cancel' to cancel): " inputValue
            else
                # Handle data corruption
                echo "Data corrupted for column '$valueName'."
                return
            fi

            if [ "$inputValue" == "cancel" ]; then
                # Handle input cancellation
                echo "Input canceled."
                return
            elif [ -z "$inputValue" ]; then
                [ "$isPrim" == "n" ] && break
                echo "Value cannot be empty for a Primary Key. Please try again."
            elif [ "$isPrim" == "y" ] && value_exists "$inputValue" "${primArr[@]}"; then
                echo "This primary key is already used, pick another value."
            elif [ $valueType == "int" ]; then
                [[ "$inputValue" =~ ^[0-9]+$ ]] && break
                echo "Please enter an integer value."
            elif [ $valueType == "string" ]; then
                [[ "$inputValue" =~ [a-zA-Z]+$ ]] && break
                echo "Please enter a string (a-zA-z) value."
            elif [ $valueType == "bool" ]; then
                [[ "$inputValue" =~ ^(true|false)$ ]] && break
                echo "Please enter a boolean value (true or false)."
            else
                echo "Invalid $valueName. Please try again or type 'cancel' to cancel input."
            fi
        done

        # Append the input value to the values file
        if ((i == linesNum)); then
            inputString+="$inputValue"
        else
            inputString+="$inputValue:"
        fi
    done

    echo -n "$inputString" >> "$valuesFile"
    echo >> "$valuesFile"
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


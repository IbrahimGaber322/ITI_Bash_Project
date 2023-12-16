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
    pkLine=""
    colArr=()
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
            pkLine="$colName:$colType:$isPK"
        else
        colArr+=("$colName:$colType:$isPK")
        fi

    done
    
   if  [ -n "$pkLine" ];then  
    
    echo "$pkLine" > "$metadataFile"
    for el in "${colArr[@]}"; do
    echo "$el" >> "$metadataFile"
    done
    echo "Table '$tableName' created successfully."
    else
     rm -r "$tableDir"
    echo "Failed to create table without primary key."
    fi
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


# Function to update data in a table
function updateTable() {
    # Prompt for table name
    read -p "Enter table name to update: " tableName
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

    # Display available columns for updating
    availableColumns=$(cut -d: -f1 "$metadataFile" | tr '\n' ' ')
    echo "Available columns for update: $availableColumns"

    # Prompt for column to update
    read -p "Enter column to update: " updateColumn

    # Validate entered column name
    if ! grep -q "^$updateColumn:" "$metadataFile"; then
        echo "Invalid column '$updateColumn'. Please enter a valid column name."
        return
    fi
    
    # Get the data type of the column to be updated
    updateColumnType=$(awk -F: -v updateColumn="$updateColumn" '$1 == updateColumn {print $2}' "$metadataFile")
    isPrim=$(awk -F: -v updateColumn="$updateColumn" '$1 == updateColumn {print $3}' "$metadataFile")

    # Prompt for WHERE condition
    read -p "Enter WHERE condition (column=value): " whereCondition

    # Read the WHERE condition
    IFS="=" read -r whereColumn whereValue <<< "$whereCondition"

    # Validate entered column name in WHERE condition
    if ! grep -q "^$whereColumn:" "$metadataFile"; then
        echo "Invalid column '$whereColumn' in WHERE condition. Please enter a valid column name."
        return
    fi
     #updateColumn = age
     #id=1             ======> whereColumn=id , whereValue=1
    
    #id:int:y                                        $1:$2:$3
    #name:string:n     updateLoc=2                   1:ibrahim:24
    #age:int:n
    updateLoc=$(awk -F: -v updateColumn="$updateColumn" '$1 == updateColumn {print NR}' "$metadataFile")
    whereLoc=$(awk -F: -v whereColumn="$whereColumn" '$1 == whereColumn {print NR}' "$metadataFile")
    # Find line numbers in values.txt that match the WHERE condition
    whereLine=($(awk -F: -v whereLoc="$whereLoc" -v whereValue="$whereValue" '$whereLoc == whereValue {print NR}' "$valuesFile"))

    # Check if any matching lines were found
    if [ ${#whereLine[@]} -eq 0 ]; then
    echo "No matching records found for WHERE condition: $whereCondition"
    return
    fi
    
    #primary keys array
    primArr=()

    while IFS=':' read -r firstValue _; do
        primArr+=("$firstValue")
    done < "$valuesFile"

    # Prompt for new value
    while true; do
        read -p "Enter new value for $updateColumn ($updateColumnType): " newValue
        #validate duplication of primary key
        if [ "$isPrim" = "y" ]; then
            if value_exists "$newValue" "${primArr[@]}"; then
                echo "Error: Primary key '$newValue' already exists. Please enter a different value."
                continue
            fi
        fi
        # Validate the new value based on the column type
        case $updateColumnType in
            "int")
                [[ "$newValue" =~ ^[0-9]+$ ]] && break
                echo "Please enter an integer value."
                ;;
            "string")
                [[ "$newValue" =~ [a-zA-Z]+$ ]] && break
                echo "Please enter a string (a-zA-Z) value."
                ;;
            "bool")
                [[ "$newValue" =~ ^(true|false)$ ]] && break
                echo "Please enter a boolean value (true or false)."
                ;;
            *)
                echo "Invalid data type for column '$updateColumn'."
                return
                ;;
        esac
    done

    ## Update the value in the values file based on the WHERE condition
    for line in "${whereLine[@]}"; do
    awk -v line="$line" -v updateLoc="$updateLoc" -v newValue="$newValue" '
        BEGIN {
            FS=":";
            OFS=":";
        }
        NR == line {
            $updateLoc = newValue;
        }
        {
            print;
        }' "$valuesFile" > "$valuesFile.tmp"

    # Replace the original values file with the updated one
    
    done
    mv "$valuesFile.tmp" "$valuesFile"
    echo "Table '$tableName' updated successfully."
}

function selectFromTable() {
    # Prompt for table name
    read -p "Enter table name to select from: " tableName
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

    # Display column headers
    headers=$(cut -d: -f1 "$metadataFile" | tr '\n' '\t')
    echo -e "Table columns:\t$headers"

    # Prompt for columns to select
    while true; do
        read -p "Enter columns you want to select separated by space. (Enter * to select all): " columns

        if [ "$columns" == "" ]; then
            return
        fi

        # If '*' is entered, select all columns
        if [ "$columns" == "*" ]; then
            columns=$(cut -d: -f1 "$metadataFile" | tr '\n' ' ')
            break
        fi

        # Validate entered column names
        invalidColumns=()
        for col in $columns; do
            if ! grep -q "^$col:" "$metadataFile"; then
                invalidColumns+=("$col")
            fi
        done

        # Display error for invalid columns
        if [ ${#invalidColumns[@]} -eq 0 ]; then
            break
        else
            echo "Invalid column(s): ${invalidColumns[*]}. Please enter valid column names."
        fi
    done

    # Prompt for WHERE condition
    read -p "Enter WHERE condition (column=value split by space for multiple conditions, type 'cancel' to exit): " inputString

    # Break the loop if 'cancel' is entered
    if [ "$inputString" == "cancel" ]; then
        return
    fi

    # Read the WHERE conditions
    read -ra whereCondition <<< "$inputString"

    # Validate entered column names in WHERE conditions
    while true; do
        invalidColumns=()
        for el in "${whereCondition[@]}"; do
            IFS="=" read -r col_name _ <<< "$el"
            if ! grep -q "^$col_name:" "$metadataFile"; then
                invalidColumns+=("$col_name")
            fi
        done

        # Display error for invalid columns
        if [ ${#invalidColumns[@]} -eq 0 ]; then
            break
        else
            echo "Invalid column(s) in WHERE condition: ${invalidColumns[*]}. Please enter valid column names."
        fi
    done

    # Display selected data
    headers=$(echo "$columns" | tr ' ' '\t')
    echo -e "$headers"
    awk -F: -v columns="$columns" -v conditions="${whereCondition[*]}" -v metadataFile="$metadataFile" '
        BEGIN {
            OFS="\t";
            split(columns, cols, " ");
            split(conditions, where, " ");

            # Read metadata and store column indices
            while (getline < metadataFile > 0) {
                split($0, metadata, ":");
                metadataIndices[metadata[1]] = ++indexCounter;
            }
            close(metadataFile);
        }
        {
            pass = 1;
            for (i in where) {
                split(where[i], condition, "=");
                col_name = condition[1];
                col_value = condition[2];
                if (metadataIndices[col_name] && $metadataIndices[col_name] != col_value) {
                    pass = 0;
                    break;
                }
            }
            if (pass) {
                for (i in cols) {
                    col_index = metadataIndices[cols[i]];
                    printf "%s\t", $col_index;
                }
                print "";
            }
        }' "$valuesFile"
}

# Function to delete a row from a table
function deleteFromTable() {
    # Prompt for table name
    read -p "Enter table name to delete from: " tableName
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

    # Prompt for WHERE condition
    read -p "Enter WHERE condition (column=value): " whereCondition

    # Read the WHERE condition
    IFS="=" read -r whereColumn whereValue <<< "$whereCondition"

    # Validate entered column name in WHERE condition
    if ! grep -q "^$whereColumn:" "$metadataFile"; then
        echo "Invalid column '$whereColumn' in WHERE condition. Please enter a valid column name."
        return
    fi

    whereLoc=$(awk -F: -v whereColumn="$whereColumn" '$1 == whereColumn {print NR}' "$metadataFile")

    # Find line numbers in values.txt that match the WHERE condition
    whereLine=($(awk -F: -v whereLoc="$whereLoc" -v whereValue="$whereValue" '$whereLoc == whereValue {print NR}' "$valuesFile"))

    # Check if any matching lines were found
    if [ ${#whereLine[@]} -eq 0 ]; then
        echo "No matching records found for WHERE condition: $whereCondition"
        return
    fi

    # Use awk to delete lines by line numbers from the file
    for (( i=${#whereLine[@]}-1; i>=0; i-- )); do
        lineNum=${whereLine[i]}
        sed -i "${lineNum}d" "$valuesFile"
    done

    echo "Rows matching WHERE condition deleted successfully from table '$tableName'."
}

# Function to drop a table
dropTable() {
    # Prompt user to enter the name of the table to drop
    read -p "Enter table name to drop: " tableName

    # Check if the specified table directory exists
    if [ -d "$1/$tableName" ]; then
        # Ask for confirmation before dropping the table
        read -p "Are you sure you want to drop table '$tableName'? (y/n): " confirm

        # If user confirms, remove the table directory
        if [ "$confirm" = "y" ]; then
            rm -r "$1/$tableName"
            echo "Table '$tableName' dropped successfully."
        else
            # If user cancels, inform them that the drop operation is canceled
            echo "Drop operation canceled."
        fi
    else
        # If the specified table does not exist, inform the user
        echo "Table '$tableName' does not exist."
    fi
}




















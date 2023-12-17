#!/bin/bash

source dbfunctions.bash
source tablefunctions.bash
shopt -s extglob


connectedDB="0"
# Bold text escape code
bold="\033[1m"

# Reset formatting escape code
reset="\033[0m"
function manageDB() {
    options=("Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Search Table" "Quit")
    select option in "${options[@]}"; do
        case $option in
            "Create Table")
                createTable $connectedDB
                ;;
            "List Tables")
                listTables $connectedDB
                ;;
            "Drop Table")
                dropTable $connectedDB
                ;;
            "Insert into Table")
                insertIntoTable $connectedDB
                ;;
            "Select From Table")
                selectFromTable $connectedDB
                ;;
            "Delete From Table")
                deleteFromTable $connectedDB
                ;;
            "Update Table")
                updateTable $connectedDB
                ;;
            "Search Table")
                searchInTable $connectedDB
                ;;        
            "Quit")
                connectedDB="0"
                main
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

function main() {
    currentDirectory=$(pwd)
    check=0
    echo $currentDirectory

    if [ -d "${currentDirectory}/database" ]; then
        echo "Database folder exists"
        check=1
    else
        echo "Database folder does not exist"
        read -p "Would you like to create one? (y for yes, n for no): " answer

        if [ "$answer" == "y" ]; then
            mkdir "${currentDirectory}/database"
            echo "Database folder created"
            check=1
        else
            echo "Exiting script"
            exit 1
        fi
    fi

    if [ "$check" == "1" ]; then
        currentDirectory="${currentDirectory}/database"
        PS3="Select an option: "
        options=("Create new database" "List databases" "Drop database" "Connect to database" "Quit")
        echo $currentDirectory

        select choice in "${options[@]}"; do
            case $REPLY in
                1)
                    # Create new database
                    createDB $currentDirectory
                    ;;
                2)
                    # List databases
                    listDB $currentDirectory
                    ;;
                3)
                    # Drop database
                    dropDB $currentDirectory
                    ;;
                4)
                    # Connect to database
                    if connectDB $currentDirectory; then
                        connectedDB="${currentDirectory}/${name}"
                        manageDB
                    fi
                    ;;
                5)
                    # Quit
                    echo "Exiting script"
                    exit 0
                    ;;
                *)
                    echo "Invalid option"
                    ;;
            esac
        done
    fi
}

echo -e "${bold} Welcome to DBMS ${reset}" #// for make it BOLD
main

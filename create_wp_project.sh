#!/bin/bash

# Define color printing functions
print_green() {
  echo -e "\e[32m$1\e[0m"
}

print_red() {
  echo -e "\e[31m$1\e[0m"
}

print_white() {
  echo -e "\e[97m$1\e[0m"
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  print_red "\nThis script must be run as root.\n"
  exit 1
fi

print_green "\nBefore running this script, make sure you have a LAMP environment set up."

print_white "\nPress Enter to continue or Esc to exit..."

# Read a single character and handle input
read -s -n 1 key

case "$key" in
    "") # Enter key
        print_green "Continuing..."
        ;;
    $'\e')  # Esc key
        print_red "Exiting..."
        exit 0
        ;;
    *)
        print_red "Invalid key pressed. Exiting..."
        exit 1
        ;;
esac

# Get the current user's Downloads directory
USER_HOME=$(eval echo ~$SUDO_USER)
DOWNLOADS_DIR="${USER_HOME}/Downloads"

# Check if the WordPress archive already exists
ARCHIVE_FILE="${DOWNLOADS_DIR}/latest.tar.gz"
if [ -f "$ARCHIVE_FILE" ]; then
    print_green "\nThe WordPress archive already exists in Downloads. Skipping download."
else
    print_white "\nDo you want to get WordPress from the official source? (y/n): "
    read response
    response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

    case "$response" in
        [yY] | [yY][eE][sS])
            print_green "\nDownloading WordPress..."
            curl -O https://wordpress.org/latest.tar.gz -o "$ARCHIVE_FILE"
            ;;
        [nN] | [nN][oO])
            print_green "You chose No."
            ;;
        *)
            print_red "Invalid response. Please enter y or n."
            exit 1
            ;;
    esac
fi

# Prompt for project name with validation
while true; do
    print_white "\nWhat will be your new project's name? "
    read project_name

    # Validate project name
    if [[ ! "$project_name" =~ ^[a-zA-Z0-9_]+$ ]]; then
        print_red "\nInvalid project name. Only alphanumeric characters and underscores are allowed."
    else
        break
    fi
done

# Create directory and move to it
dir="/var/www/html/${project_name}"
print_green "\nCreating directory $dir..."
sudo mkdir -p "$dir"
cd "$dir" || { print_red "\nFailed to change directory. Exiting..."; exit 1; }

# Extract WordPress archive without showing the files being decompressed
print_white "\nExtracting WordPress to /var/www/html/${project_name}..."
sudo tar -xzf "$ARCHIVE_FILE" -C "$dir" --strip-components=1 > /dev/null 2>&1

print_green "Extraction complete."

# Prompt for database setup instructions
print_white "\nTo complete the WordPress installation, you need to set up the MySQL database."
print_white "Run the following commands in your MySQL client, replacing placeholders with your actual values:"
print_green "\nCREATE DATABASE IF NOT EXISTS ${project_name};"
print_green "GRANT ALL PRIVILEGES ON ${project_name}.* TO 'your_db_user'@'localhost';"
print_green "FLUSH PRIVILEGES;\n"
print_red "Ensure to replace any placeholder with the actual values"

# Final cleanup options
while true; do
    print_white "\nDo you want to remove the downloaded .tar.gz file? (y/n): "
    read cleanup
    cleanup=$(echo "$cleanup" | tr '[:upper:]' '[:lower:]')

    case "$cleanup" in
        [yY] | [yY][eE][sS])
            print_green "Removing the .tar.gz file..."
            rm -f "$ARCHIVE_FILE"
            break
            ;;
        [nN] | [nN][oO])
            print_green "Keeping the .tar.gz file."
            break
            ;;
        *)
            print_red "Invalid response. Please enter y or n."
            ;;
    esac
done

print_green "\nSetup complete! Open your browser and navigate to http://localhost/${project_name} to complete the WordPress installation."
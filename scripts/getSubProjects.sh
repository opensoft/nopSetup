#!/bin/bash


NOPCOMMERCE_BINARIES_URL=""
# Check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux"
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_linux_x64.zip"
    # Check and install unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found. Attempting to install..."
        # Try apt first, then yum/dnf for broader Linux compatibility
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y unzip
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y unzip
        elif command -v yum &> /dev/null; then
            sudo yum install -y unzip
        elif command -v pacman &> /dev/null; then
            sudo pacman -S --noconfirm unzip
        else
            echo "Could not determine package manager. Please install 'unzip' manually."
            exit 1
        fi
        # Verify installation
        if ! command -v unzip &> /dev/null; then
            echo "Failed to install 'unzip'. Please install it manually and re-run the script."
            exit 1
        else
            echo "'unzip' installed successfully."
        fi
    else
        echo "'unzip' is already installed."
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Running on macOS"
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_mac_x64.zip"
    # Check and install unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found. Attempting to install..."
        if command -v brew &> /dev/null; then
            brew install unzip
        else
            echo "Homebrew not found. Please install 'unzip' manually or install Homebrew first (https://brew.sh/)."
            exit 1
        fi
        # Verify installation
        if ! command -v unzip &> /dev/null; then
            echo "Failed to install 'unzip'. Please install it manually and re-run the script."
            exit 1
        else
            echo "'unzip' installed successfully."
        fi
    else
        echo "'unzip' is already installed."
    fi
elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    echo "Running on Windows (using Cygwin/MSYS/Git Bash)"
    NOPCOMMERCE_BINARIES_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_NoSource_win_x64.zip"
    # Check for unzip
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found."
        echo "Running on Windows. Please ensure 'unzip' is installed and available in your PATH."
        echo "You might need to install it via Chocolatey ('choco install unzip') or download it manually."
        echo "Script will exit now. Please install unzip and re-run."
        exit 1
    else
        echo "'unzip' is already installed."
    fi
else
    echo "Running on an unknown OS ($OSTYPE)"
    # Check for unzip on unknown OS
    if ! command -v unzip &> /dev/null; then
        echo "'unzip' command not found on this unknown OS."
        echo "Please install 'unzip' manually and ensure it's in your PATH."
        exit 1
    else
         echo "'unzip' is already installed."
    fi
fi


# --- nopCommerce Repository Setup ---
echo "Setting up nopCommerce repository..."
if [ -d "nopCommerce/.git" ]; then
    # Directory exists and is a Git repository
    echo "'nopCommerce' directory exists. Checking out 'develop' and pulling latest changes..."
    cd nopCommerce || exit 1
    git checkout develop
    git pull origin develop # Assuming 'origin' is the remote name
    cd .. || exit 1
    echo "NopCommerce repository updated."
elif [ -d "nopCommerce" ]; then
    # Directory exists but is not a Git repository
    echo "Warning: 'nopCommerce' directory exists but is not a valid Git repository. Removing and Cloning."
    rm -rf nopCommerce # Remove the existing directory
    # Note: 'git clone' might fail if the directory is not empty.
    echo "Cloning nopCommerce repository..."
    git clone git@github.com:opensoft/nopCommerce.git nopCommerce
    if [ $? -ne 0 ]; then
        echo "Error: Cloning into existing 'nopCommerce' directory failed. It might not be empty."
        echo "Please manually clean up the 'nopCommerce' directory or remove it and run the script again."
        exit 1
    else 
        cd nopCommerce || exit 1
        git checkout develop
        cd .. || exit 1
        echo "NopCommerce repository cloned successfully."
    fi
else
    # Directory does not exist
    echo "Cloning nopCommerce repository..."
    git clone git@github.com:opensoft/nopCommerce.git nopCommerce
    cd nopCommerce || exit 1
    git checkout develop
    cd .. || exit 1
    echo "NopCommerce repository cloned successfully."
fi


# --- nopSolution Source Download and Setup ---
# This is the full source of the nopSolution framework (specific version)
# This is NOT a repo. Use this for reference or plugin development alongside the repos.
echo "Downloading nopCommerce source zip (v4.80.5)..."
curl -L -o nopCommerce_4.80.5_Source.zip https://github.com/nopSolutions/nopCommerce/releases/download/release-4.80.5/nopCommerce_4.80.5_Source.zip
echo "nopCommerce source zip downloaded."

# Create the nopSolution directory and unzip the source code into it
echo "Creating nopSolution directory and unzipping source..."
mkdir -p nopSolution
unzip -q nopCommerce_4.80.5_Source.zip -d nopSolution
echo "nopCommerce source unzipped into nopSolution directory."

# Remove files at the root of nopSolution, keep subdirectories
echo "Cleaning up root files in nopSolution..."
find nopSolution/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSolution, if any."

# Remove files at the root of nopSolution/src, keep subdirectories
echo "Cleaning up root files in nopSolution/src..."
find nopSolution/src/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSolution/src, if any."

# Clean up the downloaded zip file
echo "Removing downloaded zip file..."
rm nopCommerce_4.80.5_Source.zip
echo "Zip file removed."
echo "nopSolution source setup complete."
echo "-----------------------------------------------------" # Added separator

# --- nopPlugins Source Download and Setup ---
# This is the full source of the nopPlugins framework (specific version)
# This is NOT a repo. Use this for reference alongside the repos.
# !!! UPDATE THE URL AND VERSION (X.Y.Z) BELOW !!!
#PLUGIN_VERSION="X.Y.Z" # Replace with actual version
echo "Downloading nopCommerce Binaries zip"

# Create the nopPlugins_Source directory and unzip the source code into it
echo "Creating nopPlugins_Source directory and unzipping source..."
mkdir -p nopPlugins
curl -L -o "nopCommerce_4.80.5_binaries.zip" "${NOPCOMMERCE_BINARIES_URL}"
if [ $? -ne 0 ]; then
    echo "Error downloading nopCommerce binaries zip. Please check the URL and version."
    # Decide if you want to exit or continue:
    # exit 1 
else 
    echo "nopCommerce binaries zip downloaded successfully."
fi   
unzip -q "nopCommerce_4.80.5_binaries.zip" -d nopPlugins_Source
echo "nopPlugins source unzipped into nopPlugins_Source directory."

# Remove files at the root of nopPlugins_Source, keep subdirectories
echo "Cleaning up root files in nopPlugins_Source..."
find nopPlugins_Source/ -maxdepth 1 -type f -delete
echo "Removed files at the root of nopPlugins_Source, if any."

# Remove files at the root of nopPlugins_Source/src, keep subdirectories (if applicable)
if [ -d "nopPlugins_Source/src" ]; then
    echo "Cleaning up root files in nopPlugins_Source/src..."
    find nopPlugins_Source/src/ -maxdepth 1 -type f -delete
    echo "Removed files at the root of nopPlugins_Source/src, if any."
fi

# Clean up the downloaded zip file
echo "Removing downloaded Binaries zip file..."
rm "nopCommerce_4.80.5_binaries.zip"
echo "Binaries zip file removed."
echo "-----------------------------------------------------" # Added separator


# --- Final Messages ---
echo ""
echo "-----------------------------------------------------"
echo "nopCommerce development environment setup complete!"
echo " - nopCommerce repository cloned into 'nopCommerce/'"
echo " - nopPlugins repository cloned into 'nopPlugins/'" # This line seems incorrect based on the script logic, nopPlugins repo isn't cloned here. Consider removing or correcting.
echo " - nopCommerce v4.80.5 source extracted into 'nopSolution/' (cleaned)"
echo " - nopCommerce v4.80.5 binaries extracted into 'nopPlugins Container/' (cleaned)" # Added this line for clarity
 
echo "-----------------------------------------------------"


echo "-----------------------------------------------------"
echo "Setup finished."
echo "-----------------------------------------------------"


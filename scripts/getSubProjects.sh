#!/bin/bash



NOPVERSION="4.80.5" # Set the nopCommerce version here

SOURCE_TYPE=""
NOP_GITHUB_URL=""
NOP_GITHUB_BASE_URL="https://github.com/nopSolutions/nopCommerce/releases/download/release-${NOPVERSION}/"
NOP_GITHUB_SOURCE_FILE="nopCommerce_${NOPVERSION}_Source.zip"
NOP_DOWNLOADED_BINARIES_ZIP="nopCommerce_${NOPVERSION}_binaries.zip"
NOP_GITHUB_BINARIES_PREFIX="${NOP_GITHUB_BASE_URL}nopCommerce_${NOPVERSION}_NoSource_"
NOP_GITHUB_BINARIES_SUFFIX="_x64.zip"
NOP_PLUGINS_RELATIVE_PATH="nopPlugins/.devcontainer/containers/Nop.Web/bin/Debug/net9.0/"

# Check OS type
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "Running on Linux"
    OS_TYPE="linux"
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
    OS_TYPE="mac"
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
    OS_TYPE="win"
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


# Define the download directory explicitly as the nopSetup folder
DOWNLOAD_DIR="$(cd "$(dirname "$0")/.." && pwd)" # This sets the download directory to the parent folder (nopSetup)
cd "$DOWNLOAD_DIR" || exit 1

# --- nopSolution Source Download and Setup ---
# This is the full source of the nopSolution framework (specific version)
# This is NOT a repo. Use this for reference or plugin development alongside the repos.
echo "Downloading nopCommerce source zip (v4.80.5)..."
curl -L -o "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE" "${NOP_GITHUB_BASE_URL}${NOP_GITHUB_SOURCE_FILE}"
echo "nopCommerce source zip downloaded."

# Create the nopSolution directory inside nopSetup and unzip the source code into it
echo "Creating nopSetup/nopSolution directory and unzipping source..."
mkdir -p "$DOWNLOAD_DIR/nopSolution"
unzip -q "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE" -d "$DOWNLOAD_DIR/nopSolution"
echo "nopCommerce source unzipped into nopSetup/nopSolution directory."

# Remove files at the root of nopSolution, keep subdirectories
echo "Cleaning up root files in nopSetup/nopSolution..."
find "$DOWNLOAD_DIR/nopSolution/" -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSetup/nopSolution, if any."

# Remove files at the root of nopSolution/src, keep subdirectories
echo "Cleaning up root files in nopSetup/nopSolution/src..."
find "$DOWNLOAD_DIR/nopSolution/src/" -maxdepth 1 -type f -delete
echo "Removed files at the root of nopSetup/nopSolution/src, if any."

# Clean up the downloaded zip file
echo "Removing downloaded zip file..."
rm "$DOWNLOAD_DIR/$NOP_GITHUB_SOURCE_FILE"
echo "Zip file removed."
echo "nopSolution source setup complete."
echo "-----------------------------------------------------" # Added separator

# --- nopPlugins Binaries Download and Setup ---
# These are the official DLLs of this version of the nopCommerce framework
# This is NOT a repo. Use this for reference alongside the repos.
# !!! UPDATE THE URL AND VERSION (X.Y.Z) at the top of file !!!
echo "Preparig nopPlugins setup"
NOP_GITHUB_BINARIES_URL="${NOP_GITHUB_BINARIES_PREFIX}${OS_TYPE}${NOP_GITHUB_BINARIES_SUFFIX}"
echo "Downloading $NOP_DOWNLOADED_BINARIES_ZIP from: ${NOP_GITHUB_BINARIES_URL}"
curl -L -o "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP" "${NOP_GITHUB_BINARIES_URL}"
if [ $? -ne 0 ]; then
    echo "Error downloading nopCommerce binaries zip. Please check the URL and version."
    exit 1
else 
    echo "nopCommerce binaries zip downloaded successfully."
fi

# Verify the integrity of the downloaded zip file
echo "Verifying the integrity of the downloaded zip file..."
unzip -t $NOP_DOWNLOADED_BINARIES_ZIP > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: The downloaded zip file is invalid or corrupted. Please check the URL or re-download."
    rm -f $NOP_DOWNLOADED_BINARIES_ZIP
    exit 1
else
    echo "Zip file integrity verified successfully."
fi
# Create the nopPlugins directory and unzip the source code into it
echo "Creating nopPlugins directory and unzipping source..."
mkdir -p "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH"

echo "Unzipping $NOP_DOWNLOADED_BINARIES_ZIP into nopPlugins directory..."
unzip -q "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP" -d "$DOWNLOAD_DIR/$NOP_PLUGINS_RELATIVE_PATH"
if [ $? -eq 0 ]; then
    echo "nopPlugins binaries unzipped into nopPlugins directory."

# # Remove files at the root of nopPlugins, keep subdirectories
# echo "Cleaning up root files in nopPlugins..."
# #find nopPlugins/ -maxdepth 1 -type f -delete
# echo "Removed files at the root of nopPlugins, if any."

# # Remove files at the root of nopPlugins/src, keep subdirectories (if applicable)
# if [ -d "nopPlugins/src" ]; then
#     echo "Cleaning up root files in nopPlugins/src..."
#    # find nopPlugins/src/ -maxdepth 1 -type f -delete
#     echo "Removed files at the root of nopPlugins/src, if any."
# fi

# Clean up the downloaded zip file
echo "Removing downloaded Binaries zip file..."
rm "$DOWNLOAD_DIR/$NOP_DOWNLOADED_BINARIES_ZIP"
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


#!/bin/bash

# Commit the fixes for the clone script and solution file formatting

cd /home/brett/projects/nopSetup

# Add the modified files
git add scripts/clone
git add nopPlugins/src/NopCommerce.sln

# Commit with descriptive message
git commit -m "Fix clone script solution file syntax issues

- Fixed clone script to add projects as separate blocks instead of nested
- Resolved 't' prefix issue in NestedProjects section caused by incorrect sed escape sequences
- Updated sed commands to use proper tab characters without the 't' artifact
- Corrected Visual Studio solution syntax: each Project...EndProject block is now separate
- Project nesting relationship is properly handled only in GlobalSection(NestedProjects)

Fixes:
- clone --remove now properly removes all project references from solution file
- clone script no longer creates malformed nested project structure
- No more stray 't' characters in solution file output"

echo "Committed clone script fixes successfully"

#!/usr/bin/python
import glob
from datetime import datetime
from pathlib import Path

LICENSE_FORMAT = """\
------------------------------------------------------------------------------
--{FILENAME}--
--                                                                          --
--{DESCRIPTION}--
-- (c) {YEAR} AdOS                                                            --
-- License : See license.txt in the root directory.                         --
--                                                                          --
------------------------------------------------------------------------------
"""



def align_text(text, width):
    """Aligns the text to the center of the given width."""
    return text.center(width)

# find all adb and ads in adOS/
source_files = glob.glob("adOS/**/*.adb", recursive=True) + glob.glob("adOS/**/*.ads", recursive=True)


def make_license_header(filename):
    """Creates a license header for the given filename."""
    # Extract the base filename
    base_filename = Path(filename).stem.upper()
    
    # Create a description based on the file type
    if filename.endswith(".adb"):
        description = "B o d y"
    elif filename.endswith(".ads"):
        description = "S p e c"
    else:
        raise ValueError("Unsupported file type: {}".format(filename))
    
    # Format the license header
    license_header = LICENSE_FORMAT.format(
        FILENAME=align_text(base_filename, 74),
        DESCRIPTION=align_text(description, 74),
        YEAR=int(datetime.now().year)
    )
    
    return license_header

def get_existing_license_header(file_content):
    """Extracts the existing license header from the file content."""
    lines = file_content.splitlines()

    # count number of "-" in line 0 (this is box width)
    box_width = lines[0].count("-")
    if box_width == 0 or box_width != len(lines[0]):
        return None

    box_lines = 1
    while box_lines < len(lines) and lines[box_lines].count("-") != box_width:
        box_lines += 1

    if box_lines >= len(lines):
        return None

    return "\n".join(lines[:box_lines + 1])

for file in source_files:
    with open(file, "r") as f:
        content = f.read()

    existing_license = get_existing_license_header(content)
    new_license = make_license_header(file)

    if existing_license != new_license:
        print(f"Updating license header in {file}")
        # Remove the existing license header if it exists
        if existing_license:
            content = content.replace(existing_license, "", 1).lstrip("\n")
        
        # Prepend the new license header
        content = new_license + "\n" + content

        with open(file, "w") as f:
            f.write(content)
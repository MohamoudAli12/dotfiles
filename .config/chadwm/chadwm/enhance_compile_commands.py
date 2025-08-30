#!/usr/bin/env python3
"""
enhance_compile_commands.py
Enhances compile_commands.json with proper system includes for clangd
"""

import json
import subprocess
import os
import sys


def get_system_includes():
    """Get system include paths from the compiler"""
    try:
        # Get C++ system includes from GCC
        result = subprocess.run(
            ["gcc", "-E", "-x", "c", "-", "-v"],
            input="",
            capture_output=True,
            text=True,
        )

        lines = result.stderr.split("\n")
        includes = []
        in_include_section = False

        for line in lines:
            if "#include <...> search starts here:" in line:
                in_include_section = True
                continue
            elif "End of search list." in line:
                in_include_section = False
                continue
            elif in_include_section and line.strip():
                include_path = line.strip()
                if os.path.exists(include_path):
                    includes.append(f"-I{include_path}")

        return includes
    except Exception as e:
        print(f"Error getting system includes: {e}")
        return []


def clean_include_paths(parts):
    """Remove non-existent include paths"""
    cleaned_parts = []
    skip_next = False

    for i, part in enumerate(parts):
        if skip_next:
            skip_next = False
            continue

        if part == "-I" and i + 1 < len(parts):
            # Check if the next part is the include path
            include_path = parts[i + 1]
            if os.path.exists(include_path):
                cleaned_parts.append(part)
                cleaned_parts.append(include_path)
            else:
                print(f"Removing non-existent include path: {include_path}")
            skip_next = True
        elif part.startswith("-I"):
            # Check if the include path exists
            include_path = part[2:]
            if os.path.exists(include_path):
                cleaned_parts.append(part)
            else:
                print(f"Removing non-existent include path: {include_path}")
        else:
            cleaned_parts.append(part)

    return cleaned_parts


def enhance_compile_commands(input_file, output_file=None):
    """Enhance compile_commands.json with system includes"""
    if output_file is None:
        output_file = input_file

    # Read the original compile_commands.json
    with open(input_file, "r") as f:
        commands = json.load(f)

    # Get system includes
    system_includes = get_system_includes()
    print(f"Found {len(system_includes)} system include paths")

    # Add system includes to each command
    for entry in commands:
        if "command" in entry:
            # Split the command into parts
            parts = entry["command"].split()

            # Clean up non-existent paths first
            parts = clean_include_paths(parts)

            # Find where to insert the includes (after the compiler command)
            insert_pos = 1
            for i, part in enumerate(parts):
                if part.startswith("-"):
                    insert_pos = i
                    break

            # Insert system includes
            for include in reversed(system_includes):
                if include not in parts:
                    parts.insert(insert_pos, include)

            # Rebuild the command
            entry["command"] = " ".join(parts)

    # Write the enhanced compile_commands.json
    with open(output_file, "w") as f:
        json.dump(commands, f, indent=2)

    print(f"Enhanced compile_commands.json written to {output_file}")


if __name__ == "__main__":
    compile_commands_path = "./compile_commands.json"

    if len(sys.argv) > 1:
        compile_commands_path = sys.argv[1]

    if not os.path.exists(compile_commands_path):
        print(f"Error: {compile_commands_path} not found")
        sys.exit(1)

    enhance_compile_commands(compile_commands_path)

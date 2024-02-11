#!/bin/sh

# Generate a character card for a given character.
# Usage: ./generate-character-card.sh <character-name>

# Colors
Cyan='\033[0;36m'
Yellow='\033[0;33m'
Green='\033[0;32m'
Red='\033[0;31m'
Reset='\033[0m'

# Check if the character name is provided.
if [ -z "$1" ]; then
  echo "${Yellow}Please provide a character name.${Reset}"
  exit 1
fi

# Check if the character exists.
if [ ! -f "in/markdown/$1.md" ]; then
  echo "${Yellow}Character not found.${Reset}"
  exit 1
fi

# Change color to cyan
echo "${Cyan}Generating character card for '$1'...${Reset}"

# Activate the venv
. venv/bin/activate

# Pass the character's markdown file to the python script to convert it to yaml.
# Only errors will be printed from this, so color them red.
printf "%b" "${Red}"
python3 rpg-cards-py-obsidian-md-to-yaml/convert_character.py "in/markdown/$1.md" "in"
printf "%b" "${Reset}"

# Check if the character's yaml file exists.
if [ ! -f "in/$1.yaml" ]; then
  echo "${Yellow}Character YAML not generated. Operation aborted.${Reset}"
  exit 1
fi

# Pull the name of the character's image file from their yaml file.
image=$(grep "image:" "in/$1.yaml" | cut -d ' ' -f 2)

# Copy the character's yaml file to the Typst input location and overwrite the file there, if present.
mv "in/$1.yaml" rpg-cards-typst-templates/in/character.yaml

# Copy the character's image to the Typst input location and overwrite the file there, if present.
cp "in/images/$image" "rpg-cards-typst-templates/in/$image"

# Run the character card generation script.
typst compile rpg-cards-typst-templates/src/cards/character/landscape.typ "out/$1.pdf" --root rpg-cards-typst-templates

# Clean up the Typst input location.
rm "rpg-cards-typst-templates/in/character.yaml"
rm "rpg-cards-typst-templates/in/$image"

# Check if the character card was generated.
if [ ! -f "out/$1.pdf" ]; then
  echo "${Yellow}Character card failed to generate.${Reset}"
  exit 1
fi

echo "${Green}Character card for '$1' generated successfully.${Reset}"
echo

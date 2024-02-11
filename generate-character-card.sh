#!/bin/sh

# Generate a character card for a given character.
# Usage: ./generate-character-card.sh <character-name>

# Check if the character name is provided.
if [ -z "$1" ]; then
  echo "Please provide a character name."
  exit 1
fi

# Check if the character exists.
if [ ! -f "in/markdown/$1.md" ]; then
  echo "Character not found."
  exit 1
fi

# Pass the character's markdown file to the python script to convert it to yaml.
python rpg-cards-py-obsidian-md-to-yaml/convert_character.py "in/markdown/$1.md" "./out/yaml"

# Copy the character's yaml file to the Typst input location and overwrite the file there, if present.
cp "out/yaml/$1.yaml" "rpg-cards-typst-templates/in/character.yaml"

# Pull the name of the character's image file from their yaml file.
image=$(grep "image:" "out/yaml/$1.yaml" | cut -d ' ' -f 2)

# Copy the character's image to the Typst input location and overwrite the file there, if present.
cp "in/images/$image" "rpg-cards-typst-templates/in/$image"

# Run the character card generation script.
typst compile rpg-cards-typst-templates/src/cards/character/landscape.typ "out/pdf/$1.pdf" --root rpg-cards-typst-templates
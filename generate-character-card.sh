#!/bin/sh

# Generate a character card for a given character if a string is passed.
# Processes all characters in a directory if the -d flag is passed instead.
# Usage: ./generate-character-card.sh [-d] <character-name-or-input-directory>

# Colors
Cyan='\033[0;36m'
Yellow='\033[0;33m'
Green='\033[0;32m'
Magenta='\033[0;35m'
Red='\033[0;31m'
Reset='\033[0m'

# Make a .png copy of a .jpg image or vice versa.
# Usage: switchPngAndJpgExtension <image-path>
switchPngAndJpgExtension() {
  # Check if the image path is provided.
  if [ -z "$1" ]; then
    echo "${Yellow}Please provide an image path.${Reset}"
    return 1
  fi

  # Check if the image exists.
  if [ ! -f "$1" ]; then
    echo "${Yellow}Image not found.${Reset}"
    return 1
  fi

  # Pull the file extension from the image path.
  extension=$(echo "$1" | rev | cut -d '.' -f 1 | rev)

  # Check if the file extension is .png or .jpg.
  if [ "$extension" = "png" ]; then
    # Make a .jpg copy of the .png image.
    cp "$1" "$(echo "$1" | sed 's/.png/.jpg/')"
  elif [ "$extension" = "jpg" ]; then
    # Make a .png copy of the .jpg image.
    cp "$1" "$(echo "$1" | sed 's/.jpg/.png/')"
  else
    echo "${Yellow}Image file extension not supported.${Reset}"
    return 1
  fi

  return 0
}

# Replace the text of the "image: " line in a given YAML file with a new file extension.
# Usage: updateYamlImageExtension <yaml-file> <new-extension>
updateYamlImageExtension() {
  # Check if the YAML file and new extension are provided.
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "${Yellow}Please provide a YAML file and a new extension.${Reset}"
    return 1
  fi

  # Check if the YAML file exists.
  if [ ! -f "$1" ]; then
    echo "${Yellow}YAML file not found.${Reset}"
    return 1
  fi

  # Replace the text of the "image: " line in the YAML file with the new file extension.
  sed "s/image: .*/image: $2/" "$1" >"$1.tmp"
  mv "$1.tmp" "$1"

  return 0
}

generateCharacter() {
  # Generate a character card for a given character.
  # Usage: generateCharacter <character-name>

  markdownDirectory="in/markdown"
  imageDirectory="in/images"
  typstDirectory="rpg-cards-typst-templates"
  pyDirectory="rpg-cards-py-obsidian-md-to-yaml"

  # Check if the character name is provided.
  if [ -z "$1" ]; then
    echo "${Yellow}Please provide a character name.${Reset}"
    return 1
  fi

  # Check if the character exists.
  if [ ! -f "$markdownDirectory/$1.md" ]; then
    echo "${Yellow}Character not found.${Reset}"
    return 1
  fi

  # Change color to cyan
  echo "${Cyan}Generating character card for '$1'...${Reset}"

  # Pass the character's markdown file to the python script to convert it to yaml.
  # Only errors will be printed from this, so color them red.
  printf "%b" "${Yellow}"
  python3 $pyDirectory/convert_character.py "$markdownDirectory/$1.md" "in"
  printf "%b" "${Reset}"

  # Check if the character's yaml file exists.
  filename="in/$1.yaml"
  if [ ! -f "$filename" ]; then
    echo "${Yellow}Character YAML not generated. Operation aborted.${Reset}"
    return 1
  fi

  # Pull the name of the character's image file from their yaml file.
  image=$(grep "image:" "in/$1.yaml" | cut -d ' ' -f 2)

  # Copy the character's yaml file to the Typst input location and overwrite the file there, if present.
  mv "in/$1.yaml" $typstDirectory/in/character.yaml

  # Copy the character's image to the Typst input location and overwrite the file there, if present.
  # If the image is not there, abort processing.
  if [ ! -f "$imageDirectory/$image" ]; then
    echo "${Red}Character image '$imageDirectory/$image' not found. Operation aborted.${Reset}"
    return 1
  fi
  cp "$imageDirectory/$image" "$typstDirectory/in/$image"

  # Run the character card generation script.
  {
    # Suppress errors from the Typst command, as they are not helpful.
    typst compile $typstDirectory/src/cards/character/landscape.typ "out/$1.pdf" --root $typstDirectory 2>/dev/null
  } || {
    # If the previous compile failed, it might be because the image has the wrong file extension. Try converting between png/jpg and try again.
    {
      echo "${Yellow}Character card failed to generate. Attempting to convert image file extension...${Reset}"
      switchPngAndJpgExtension "$typstDirectory/in/$image"
      # The "image" text in the YAML file needs to be updated to reflect the new file extension.
      updateYamlImageExtension "$typstDirectory/in/character.yaml" "$(echo "$image" | sed 's/.png/.jpg/')"
    } || {
      echo "${Red}Character card failed to generate.${Reset}"
      return 1
    }
    {
      typst compile $typstDirectory/src/cards/character/landscape.typ "out/$1.pdf" --root $typstDirectory
    } || {
      echo "${Red}Character card failed to generate.${Reset}"
      return 1
    }
    typst compile $typstDirectory/src/cards/character/landscape.typ "out/$1.pdf" --root $typstDirectory
  }

  # Clean up the Typst input location.
  {
    rm "$typstDirectory/in/character.yaml"
  } || { true; }
  {
    rm "$typstDirectory/in/$image"
  } || { true; }

  # Check if the character card was generated.
  if [ ! -f "out/$1.pdf" ]; then
    echo "${Red}Character card failed to generate.${Reset}"
    return 1
  fi

  echo "${Green}Character card for '$1' generated successfully.${Reset}"
  echo
}

# Activate the venv
. venv/bin/activate

# Check if the -d flag is passed.
if [ "$1" = "-d" ]; then
  echo "${Magenta}Generating character cards for all characters...${Reset}"
  echo

  # Run the character card generation script for all characters in the markdown directory.
  for file in in/markdown/*.md; do
    character=$(basename "$file" .md)
    {
      generateCharacter "$character"
    } || {
      echo "${Red}Skipping character card generation...${Reset}"
      echo
    }
  done

  echo "${Green}All character cards generated successfully.${Reset}"
  echo
  exit 0
fi

# Generate a character card for a given character.
generateCharacter "$1"

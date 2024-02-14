pyProjectDir="rpg-cards-py-obsidian-md-to-yaml"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
if [ -f "./$pyProjectDir/requirements.txt" ]; then
    . venv/bin/activate
    pip3 install -r "$pyProjectDir/requirements.txt"
fi

apk add --update --no-cache python3
ln -sf python3 /usr/bin/python
python3 -m ensurepip
pip3 install --no-cache --upgrade pip setuptools
pyProjectDir="rpg-cards-py-obsidian-md-to-yaml"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
if [ -f "./$pyProjectDir/requirements.txt" ]; then
    . venv/bin/activate
    pip3 install -r "$pyProjectDir/requirements.txt"
fi

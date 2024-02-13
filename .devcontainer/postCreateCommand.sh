apk add --update --no-cache python3
ln -sf python3 /usr/bin/python
python3 -m ensurepip
pip3 install --no-cache --upgrade pip setuptools
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi
if [ -f "requirements.txt" ]; then
    source venv/bin/activate
    pip3 install -r requirements.txt
fi

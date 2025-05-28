
#!/data/data/com.termux/files/usr/bin/bash

LINKER=~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/plate_profile_linker.py
MUTATOR=identity_mutator.py

# Переместить mutator
mv ~/storage/downloads/$MUTATOR ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/
chmod +x ~/storage/shared/Projects/wheelzone/bootstrap_tool/scripts/$MUTATOR

# Вставка в linker
if ! grep -q identity_mutator "$LINKER"; then
    sed -i '1i\nfrom scripts.identity_mutator import generate_identity' $LINKER
    sed -i '/def generate_profile()/, /}/c\ndef generate_profile():\n    return generate_identity()' $LINKER
fi

# Git
cd ~/storage/shared/Projects/wheelzone/bootstrap_tool || exit 1
git checkout main || git switch main
git pull --rebase origin main
git add scripts/plate_profile_linker.py scripts/identity_mutator.py
git commit -m "IDENTITY | Уникальный фингерпринт личности внедрён в генератор профилей"
git push

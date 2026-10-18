# Run on the server by server-keys.yml, after lines setting `tag` to the
# project's label and writing its keys to ~/.ssh/layered_keys.
#
# Keeps every line of authorized_keys but the project's own, then adds the
# project's keys.
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
grep -vF -e "$tag" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.layered || [ $? -eq 1 ]
cat ~/.ssh/layered_keys >> ~/.ssh/authorized_keys.layered
rm ~/.ssh/layered_keys
chmod 600 ~/.ssh/authorized_keys.layered
mv ~/.ssh/authorized_keys.layered ~/.ssh/authorized_keys

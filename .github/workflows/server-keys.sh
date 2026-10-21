# Run on the server by server-keys.yml, after lines setting `tag` to the
# project's label and `keys` to a file holding its keys.
#
# Keeps every line of authorized_keys but the project's own, then adds the
# project's keys. Holds ~/.ssh/.layered.lock while it does, as remove.yml does
# taking a key off, so runs for other projects and apps on the server wait
# rather than overwrite each other's changes.
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
command -v flock > /dev/null || { echo "flock isn't installed on the server (it's in util-linux)" >&2; exit 1; }
exec 9> ~/.ssh/.layered.lock
flock -w 120 9 || { echo "Timed out waiting for another change to the server's keys" >&2; exit 1; }
touch ~/.ssh/authorized_keys
grep -vF -e "$tag" ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.layered || [ $? -eq 1 ]
cat "$keys" >> ~/.ssh/authorized_keys.layered
rm "$keys"
chmod 600 ~/.ssh/authorized_keys.layered
mv ~/.ssh/authorized_keys.layered ~/.ssh/authorized_keys

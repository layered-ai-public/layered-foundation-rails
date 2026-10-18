# Run on the server by server-keys.yml, after lines setting `tag` to the
# project's label and writing its keys to ~/.ssh/layered_keys.
#
# Keeps every line of authorized_keys but the project's own and any holding a
# key about to be written (an older copy, under another label), then adds the
# project's keys.
set -e
mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
awk -v tag="$tag" 'NR == FNR { sent[$2] = 1; next } index($0, tag) == 0 && !($2 in sent)' \
  ~/.ssh/layered_keys ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.layered
cat ~/.ssh/layered_keys >> ~/.ssh/authorized_keys.layered
rm ~/.ssh/layered_keys
chmod 600 ~/.ssh/authorized_keys.layered
mv ~/.ssh/authorized_keys.layered ~/.ssh/authorized_keys

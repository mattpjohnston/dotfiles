# dotfiles

helix, ghostty, zed.

```bash
git clone https://github.com/mattpjohnston/dotfiles.git ~/repos/dotfiles
cd ~/.config
for d in helix ghostty zed; do
  [ -e "$d" ] && mv "$d" "$d.bak"
  ln -s ~/repos/dotfiles/$d "$d"
done
```

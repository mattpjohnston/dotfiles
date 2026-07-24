# dotfiles

helix, sway, ghostty, zed, waybar, mako, fuzzel.

```bash
git clone https://github.com/mattpjohnston/dotfiles.git ~/repos/dotfiles
cd ~/.config
for d in helix sway ghostty zed waybar mako fuzzel; do
  [ -e "$d" ] && mv "$d" "$d.bak"
  ln -s ~/repos/dotfiles/$d "$d"
done
```

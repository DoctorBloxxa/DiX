# DiX

Replacement for DeX, an instance explorer.

This intends to be lightweight and easy to use.


**The stable branch is master** (as in, master record.)

If you desire to get the latest and newest commits before they're merged onto the master branch, use the **canary** branch instead. Don't be surprised if things don't work, though.

# Problems?

File an issue. Simple.

## Limitations

The icons used are the legacy ones. There's no way around that (without resorting to mass uploading decals or uploading my own spritesheet), since the roblox player is uncapable of fetching Studio's icons.

There's also the fact that this is expected to be run at a security context 2 (LocalScript). 

Roblox's scrollingframe starts getting laggy once there's a lot of loaded items. I can't do much about it.

I also considered adding a watchdog so you can play while it's loading children. However, I'm not sure about race conditions and requires further testing.
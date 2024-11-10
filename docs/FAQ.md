# FAQ

## General

Q: Can I change the alert sound?

A: Yes, replace the files in the ```music/``` folder. 
This can only be done in desktop platforms.

Q: The alert sound does not play.

A: The format of music files must be .wav.
If this cannot be solved, either copy the original music folder to your program directory, 
or reinstall the program if an installer is available.

Q: In Linux, the UI are in light mode even when my desktop is dark mode.

A: This is a Qt bug, where initial color scheme value is set but gets overwritten
by the built-in theme.

## Technical

Q: Why is there backend logic in UI everywhere?

A: At the beginning, the main purpose for this project is try to work
with only one main QML file with everything and one very small C++ file. 
It sticks, even now.

Q: posix.wait(): .fork(), .exec(), .wait() and .redirect2null() are deprecated, use rpm.spawn() or rpm.execute() instead

A: In newer Fedora versions, package behavior are changed. This behavior is normal.

Q: Why ```set(CMAKE_INSTALL_BINDIR "." CACHE PATH "" FORCE)``` ?

A: This is to allow output executable to be in the root of the export folder instead of the bin/ folder, 
which is many user's desired layout.

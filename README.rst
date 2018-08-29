VLClive
=======

Overview
--------

VLClive is an extension that integrates livestreamer (https://github.com/chrippa/livestreamer)
into the famous VLC media player.
VLClive is written in Lua and uses the VLC Lua plugin interface.

Current Capabilities
--------------------

Note: VLClive currently only works with twitch.tv streams but it is planned to support all the streams
that are available for livestreamer in the future.

- Add/Remove your favourite streamers for quick access
- Import all your favourite streamers from twitch.tv with one click
- Quickly check if your favourite streamers are online
- Use all available quality settings


Installation
------------

1. Install Livestreamer: http://docs.livestreamer.io/install.html
(If you use Windows, add it to the Path Variable as well!)

2. Download the Lua file from /src/VLClive.lua

3. Place it in the correct folder:

  * Windows: <Path_to_VLC_installation_directory>\\lua\\extensions\\
  * Linux: ~/.local/share/vlc/lua/extensions/
  * Mac OS X: /Applications/VLC.app/Contents/MacOS/share/lua/extensions/

4. Run it from the 'View' tab in VLC

5. Please report all bugs immediately :)

6. Thank you for giving it a shot, much appreciated


Contributing
------------

If you wish to report a bug or contribute code, please take a look
at `CONTRIBUTING.rst <CONTRIBUTING.rst>`_ first.

VLClive
=======

Overview
--------

VLClive is an extension that integrates livestreamer (https://github.com/chrippa/livestreamer)
into the famous VLC media player.
VLClive is written in LUA and uses the VLC LUA plugin interface.

Current Capabilities
--------------------

Note: VLClive currently only works with twitch.tv streams but it is planned to support all the streams
that are available for livestreamer in the future.

- Add/Remove your favourite streamer for fast access
- Quickly check if your favourite streamers are online
- Use all available quality settings.


Installation
------------

<ol> <li>Livestreamer setup: <ol> <li>On Windows: <ul> <li>Download the livestreamer zip file located here: http://livestreamer.readthedocs.org/en/latest/install.html#windows-binaries</li><li>Unzip the folder and move its content to your_vlc_installation_folder/vlclive/livestreamer/<livestreamer_files></li></ul> </li><li>On Mac OS X: <ul> <li>Use the installation routine for Mac OS X: # easy_install -U livestreamer</li></ul> </li><li>Other distributions: not yet tested/supported</li></ol> </li><li> Copy the file VLClive.lua into the following folder: <ul> <li>Windows: your_vlc_installation_folder/lua/extensions</li><li>Mac OS X: VLC > Show Package Contents -> Contents/MacOS/share/lua/extensions</li></ul> </li><li>Your done! Start using it from the VLC extension tab.</li></ol>

Contributing
------------

If you wish to report a bug or contribute code, please take a look
at `CONTRIBUTING.rst <CONTRIBUTING.rst>`_ first.

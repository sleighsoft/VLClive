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

1. Copy the file VLClive.lua into the folder your_vlc_installation_folder/lua/extensions
2.1. On Windows: Download the livestreamer zip file located here: http://livestreamer.readthedocs.org/en/latest/install.html#windows-binaries
2.1.1. Unzip the folder and move its content to your_vlc_installation_folder/vlclive/livestreamer/<livestreamer_files>
2.2. On Mac OS X: Use the installation routine for Mac OS X: # easy_install -U livestreamer
2.3. Not yet tested for other distributions
3. Your done! Start using it from the VLC extension tab.

Contributing
------------

If you wish to report a bug or contribute code, please take a look
at `CONTRIBUTING.rst <CONTRIBUTING.rst>`_ first.

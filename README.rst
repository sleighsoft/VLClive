VLClive
=======

If you like it, consider donating :)

.. image:: https://www.paypalobjects.com/de_DE/DE/i/btn/btn_donate_SM.gif
    :target: https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=55J29E7JKV3GU

Overview
--------

VLClive is an extension that integrates livestreamer (https://github.com/chrippa/livestreamer)
into the famous VLC media player.
VLClive is written in LUA and uses the VLC Lua plugin interface.

Current Capabilities
--------------------

Note: VLClive currently only works with twitch.tv streams but it is planned to support all the streams
that are available for livestreamer in the future.

- Add/Remove your favourite streamer for fast access
- Quickly check if your favourite streamers are online
- Use all available quality settings.


Installation
------------

Livestreamer setup:

1. On Windows:

  1. Download the livestreamer zip file located here: http://livestreamer.readthedocs.org/en/latest/install.html#windows-binaries
  2. Unzip the folder and move its content to your_vlc_installation_folder/vlclive/livestreamer/<livestreamer_files>
 
2. On Mac OS X:

  1. Use the installation routine for Mac OS X: # easy_install -U livestreamer
  
3. Other distributions: not yet tested/supported

VLClive setup:

2. Copy the file VLClive.lua into the following folder:

  1. Windows: your_vlc_installation_folder/lua/extensions
  2. Mac OS X: VLC > Show Package Contents -> Contents/MacOS/share/lua/extensions
  3. Linux : /usr/share/vlc/lua/extensions (you might need to create the extensions folder)

You're done! Start using it from the VLC extension tab.


Contributing
------------

If you wish to report a bug or contribute code, please take a look
at `CONTRIBUTING.rst <CONTRIBUTING.rst>`_ first.

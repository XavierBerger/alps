#How to use custom protocol handler to start application from html link

# Linux #
A custom xdg-open script can handle custom protocol and allow autologin on every components.
Note: Autologin is only avilable for Linux.

Execute ./xdg-open.alps.pl  --manual and follow the instructions

# Windows #
On your local workstation, download the following application:
http://customurl.codeplex.com/

Once the executable is launched click Add and enter the following (the following assumes you are using Putty for SSH / Telnet, and that putty.exe is in the PATH, otherwise, provide the full path to putty.exe):

  * Protocol: rdp
  * Application: mstsc.exe
  * Arguments: /v:%Host%:%Port%

Click OK, and click Add again:

  * Protocol: ssh
  * Application: putty.exe
  * Arguments: -ssh %Host% -P %Port%

Click OK, and click Add again:

  * Protocol: telnet
  * Application: putty.exe
  * Arguments: -telnet %Host% -P %Port%

Click OK.

You can now close the application and open Firefox.

Once you will click on a link it will prompt you to select a handlers.
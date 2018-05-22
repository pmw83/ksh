# daynight.ksh script

This KSH shell script is based off of Dave Taylor's example work here, which unfortunately no longer works :

https://www.linuxjournal.com/article/10860

In addition to being changed to a Korne shell script, it also has been enhanced and modified to :

*Check that the needed curl binary is installed, and if it isn't attempt to determine the Linux distro and present the user with the necessary command to install it

*Correctly parse the sunrise and sunset times from the output (rise_nextpriv has changed to rise_results, and the necessary parameters to cut also needed updating)

*Prompt the user for the zipcode as input as opposed to statically defining it at the top of the script

*Validate the zipcode input

*Parse and obtain the locality (town/city) name of the zipcode input

*Parse and obtain the timezone of the zipcode input


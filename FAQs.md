

# FAQ's #
## iNXT Remote: ##
### Why does the battery level seem inaccurate? ###
**The settings pane doesn't show 0 millivolts, but the battery progress bar shows none?**

There are several things behind this.  First, the NXT reports its battery level in millivolts, However, long before it reaches 0, the AA's that power it will be drained of energy.  The battery progress bar is based on the battery indicator levels on the NXT itself.  7500 millivolts and up is 100% on the bar, 6100 and down is empty and flashing.  Yes, the NXT will continue to run below that, but the motors will start being really slow.

### Why does the file list on the NXT have to load every time? ###
The file list might change between sessions, since other programs and users might insert or delete files, and the file list has to rebuild completely anyways to find out what is no longer there, or what is new.

### Why can't I run/download/transfer/etc this file? ###
If you are presently downloading or uploading a file, building or rebuilding the NXT file list or running another program, iNXT Remote blocks you from doing another file system task till that one is completed, this is to prevent errors in file transfer, or file list generation, as I can only figure out how to have one file open on the NXT at any given time.

### I want a direct bluetooth connection! ###
This is the one feature I will not be able to implement, unfortunately I do not have access to those abilities on the iPhone.  If you really want to have this, I suggest filing a suggestion with Apple to allow their developers full bluetooth access.

### I want some other feature: ###
Feel free to leave a message here on this board, or via email.  I can't promise to add everything that is wanted, but I will at least look into what people want.

### Built in web server: ###
When I download a file via Safari 4, it just gets labeled DownloadedFile
This again, I am unsure why it is doing that, but trust me, the file is still the same file, I have tested relabeling and adding their extensions these files and using them and they work fine.  I will endeavor to fix this in the near future.

## Server: ##
### Why can't I connect via cell signal to my server? ###
There are many things that might be interfering, and I won't go into detail on all of them, but be sure the port is being properly forwarded by your router, be sure the server is on and connected to the NXT.  Remember, the best bet at connecting is via WiFi, and while connecting cell signal is certainly possible I can't do anything for the vagrancies of Cellular service providers, or the internet in general.

### I can connect, but the NXT isn't responding ###
Be sure and check that the NXT is connected to the server, presently the server doesn't ping the connection to keep the NXT alive, this is a feature that will come potentially in the future.
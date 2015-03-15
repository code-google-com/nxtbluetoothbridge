

First of all, on either Windows, or Mac, it is easiest to make sure your NXT is set up to connect via bluetooth before trying to run either server.
Next, it diverges based on whether you are using Anders' Window's based server, or my OSX based server.

# OSX: #
First off, download the disk image from [here](http://code.google.com/p/nxtbluetoothbridge/). Drag NXTBluetoothBridge to your Applications folder. To run, just double click it.
For OSX, a basic setup only requires that you hit the Connect button to connect to an NXT, and Start Server to actually start it up.
For connecting locally, just open iNXT Remote, and click connect, and the server should already be listed there thanks to Bonjour. The default password is sent if the password box on the dialog is left blank.

# Windows: #
First, download the server from [Ander's site](http://www.norgesgade14.dk/networkserver.php). Save it to wherever you wish to have it at to run it, as it is a bare .exe file. To run, just double click on it.

For Windows, the setup is slightly more complicated, first, you will need to find the comm port your NXT is set to connect on. This can be found by going into control panel, Bluetooth Devices, the Comm port tab, and finding the "incoming" listing next to your NXT's name. Set this in the bluetooth connection box on the server.

Make sure your NXT is on and ready, and hit "start server". Now you will need to know your computer's IP address to connect to it. Again, in control panel, network connections, your active connection, right click, and click "Status", go to the support tab, and there is your IP address.

Ok, with that bit of info, we are ready to connect the iPhone/iPod Touch (make sure you are on the same local network for the purposes of this tutorial). Open iNXT Remote, click connect, click the manual button in the upper left corner of the display, and enter the IP address in the IP address field, and 1000 in the port field (the default port on Anders server), close the keyboard by hitting done. Hit connect, and you should be presented with the password dialog, again, just hit ok for the default password to be sent.
After that, close out of the connecting screen and you should be all set to control your NXT.

# Firewalls: #
A quick note about Firewalls, regardless of whether you are on OSX, or Windows. This program needs to accept connections coming in from at least the local network, and if doing remote connections, the internet. If your firewall asks you to allow the program to accept incoming connections, say yes. Note that I provide no warranty on what else might happen as a result of this, open up your firewall at your own risk.

# Remote Connections: #
Remote connections are similar to the manual connections used by all Windows users, with one big extra step. This is for advanced users only. Please be familiar with port forwarding and potential risks before continuing!

First, it is good to make sure this will work over the local network before trying anything more advanced. Second, only manual connections are available at this time, and wide area Bonjour is not presently supported.

After getting your server running locally, if running behind a NAT router, you will need to set up port forwarding. This varies widely depending on the make and model of your router. Google is a great resource for finding directions for setting up port forwarding on your particular router. You will generally need to know several things, your computers IP (which needs to be set to some form of fixed IP on the router), the port of your server, either the default TCP port 8884 for OSX, TCP port 1000 for Windows, or whatever you set either to use on TCP.

On the iPhone, you will need to know your network's external IP. A good way to find this is to go to http://www.whatismyip.org/ on your computer. Enter this, and your port number, and connect. As a reminder, even a successful connection will take potentially far longer to connect, and may be very slow in its control of the robot, especially over a cell network to your home network. I can provide no warranty that connecting via a cell network will work at all, much less be usable.

# Hostname: #
As a final note, if you have a domain name set up to access your home network remotely, or a local domain name you would prefer to use to connect, just enter that instead of the IP address in any of the above situations. Note that I have not tested all scenario's with this, if you notice a bug, please let me know and I shall go about trying to fix it. If given both an IP address, and a hostname, it will choose to use the IP instead (the hostname will then just be used as the display name for the connection).
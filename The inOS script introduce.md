# The inOS script introduce

These scripts can help you to build inOS from scratch.

You can build inOS in two ways:

1. Use these scripts to build inOS in your native CentOS directly;
2. Use these scripts to build a iso file and burn it to your DVD or U-disk to install inOS on a scratch machine.

## Build inOS directly
1. Clone the repository from github.com to your /opt directory
	<pre><code> # git clone https://github.com/inspursoft/inOS.git /opt/inOS	</code></pre>
2. Change to the dir and run script directly
	<pre><code> # cd /opt/inOS
	# ./inOS-build.sh</code></pre>
3. When the script finished successfully, you can reboot your machine and start inOS by the grub2 boot menu's new entry named 'inOS-docker'.
4. You can use parameters to change the applications in inOS and something else. For example, you can use --rootpasswd to set inOS's root password. Type --help for detail.

## Build the inOS install ISO file
1. To build inOS install ISO file, you should first download the basic rpm packages. For packages list, see [here](file://./list).
2. Clone the repository from github.com to your /opt directory
	<pre><code> # git clone https://github.com/inspursoft/inOS.git /opt/inOS	</code></pre>
3. Move the downloaded rpm packages to the /opt/inOS/repos directory, and run 
	<pre><code> # pushd /opt/inOS/repos
	# createrepo ./
	# popd</code></pre>
4. Change to the dir and run script
	<pre><code> # cd /opt/inOS
	# ./inOS-buildinstall.sh</code></pre>
5. When the script finished successfully, the inOS install ISO file will be located in /opt/inOS directory, named "inOS.iso".
6. You can burn the inOS.iso into your DVD or U-disk, and boot up from them to install the inOS into your scratch machine.

# autorun
Execute scripts when connecting external drives (USB / eSATA) on a Synology NAS.


# install
Add https://www.cphub.net/ in the Package Center (current DSM only) or manually install one from the releases (for older DSM):

* DSM 7: 1.8 and 2.0.x
* DSM 6: 1.7
* DSM 5: 1.6
* older: 1.3

Third Party packages are restricted by Synology in DSM 7. Since autorun does require root 
permission to perform its job an additional manual step is required after the installation.

SSH to your NAS (as an admin user) and execute the following command:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```


# build
Should run on any *nix box / subsystem.
Variant A:
  * adjust the version number in INFO.sh
  * Generate the *.spk by execution of ./build
  * publish the created .spk
Variant B:
  * adjust the version number in INFO.sh
  * Put it to the 'source' directory of the Synology Toolkit framework
    https://github.com/SynologyOpenSource/pkgscripts-ng
  * publish the created .spk

*Note that almost all of the UI is currently not included in the build (since I got bored of updating that with more or less every DSM version).*

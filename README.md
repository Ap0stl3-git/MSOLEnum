# MSOLEnum
Modification of Beau Bullock (@dafthack)'s MSOLSpray.ps1 script to be used for User ID enumeration and/or password spraying against Microsoft Online accounts (Azure/O365).  MSOLSpray.ps1 can be found here... [//dafthack/MSOLSpray](https://github.com/dafthack/MSOLSpray)

EXAMPLE
        
C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -Password TESTPASS -OutFile validusers.txt -Domain company.com -Sleep 61

or

C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -PWList .\pwlist.txt -OutFile validusers.txt -Domain company.com -Sleep 61


## Userlist

The *userlist.txt* file should be a list of userID's without the *@company.com* suffix such as those included in the repository.

The two files, *AD-1000-Username-list.txt* and *AD-5000-Username-list.txt*, consist of the top 1000 and 5000 US last names each with a-z prepended to them.

For example:

asmith

bsmith

csmith

.

.
UK-AD-1000-Usernames-list.txt is the same as the above but with UK top lastnames

UK-first-dot-lastnames.txt contains the top 1000 UK last names with the top 100 UK male first names and top 106 UK female names in a first.last format.


AD-1000-Username-list.txt = 26,000 usernames

AD-5000-Username-list.txt = 130,000 usernames

UK-AD-1000-Usernames-list.txt = 26,000 usernames

UK-first-dot-lastnames.txt = 206,000 username


## Password List

The *pwlist.txt* file allows for iterating through a list of passwords rather than just a single password attempt.  Either method can be used -Password for single password or -PWList for password file.


## Sleep

Added ability to configure a pause between each authentication attempt.  This can be used to overcome the MSOL Smart Lockout feature by spacing authentication attempts far enough apart.

This can also be used in conjunction with the -PWList feature to setup a fire-n-forget usage.  For example, you can load a list with 15 passwords to spray and if you have, for example, 20 users and want to spray 2 passwords every 60 minutes...some quick math will give you 60-min / 2-password / 20-users = 1 auth every 1.5 mins (90 seconds), recommend settting the Sleep value to 91 to be safe.
Then it will just run for you through the 20 users and 15 passwords spaced enough per auth to ensure you only spray 2 passwords every hour.

If using a Password list, the tool will pause for confirmation before beginning the spray to display the expected per-password spray time given the number of user accounts and provided -sleep interval to allow the user to verify the math before spraying.  Simply hit "N" and configure a new -sleep time if approximate spray duration is not as desired.

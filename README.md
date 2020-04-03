# MSOLEnum
Modification of Beau Bullock (@dafthack)'s MSOLSpray.ps1 script to be used for User ID enumeration.  MSOLSpray.ps1 can be found here... [//dafthack/MSOLSpray](https://github.com/dafthack/MSOLSpray)

EXAMPLE
        
C:\PS> Invoke-MSOLEnum -UserList .\userlist.txt -Password TESTPASS -OutFile validusers.txt -Domain company.com

##Userlist

The *userlist.txt* file should be a list of userID's without the *@company.com* suffix such as those included in the repository.

The two files, *AD-1000-Username-list.txt* and *AD-5000-Username-list.txt*, consist of the top 1000 and 5000 US last names each with a-z prepended to them.

For example:
asmith
bsmith
csmith
.
.

AD-1000-Username-list.txt = 26,000 usernames
AD-5000-Username-list.txt = 130,000 usernames


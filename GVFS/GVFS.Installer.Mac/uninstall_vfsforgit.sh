#!/bin/bash

KEXTFILENAME="PrjFSKext.kext"
VFSFORDIRECTORY="/usr/local/vfsforgit"
PRJFSKEXTDIRECTORY="/Library/Extensions"
LAUNCHDAEMONDIRECTORY="/Library/LaunchDaemons"
LAUNCHAGENTDIRECTORY="/Library/LaunchAgents"
LOGDAEMONLAUNCHDFILENAME="org.vfsforgit.prjfs.PrjFSKextLogDaemon.plist"
SERVICEAGENTLAUNCHDFILENAME="org.vfsforgit.service.plist"
GVFSCOMMANDPATH="/usr/local/bin/gvfs"
UNINSTALLERCOMMANDPATH="/usr/local/bin/uninstall_vfsforgit.sh"
INSTALLERPACKAGEID="com.vfsforgit.pkg"
KEXTID="org.vfsforgit.PrjFSKext"

function UnloadKext()
{
    kextLoaded=`/usr/sbin/kextstat -b "$KEXTID" | wc -l`
    if [ $kextLoaded -eq "2" ]; then
        unloadCmd="sudo /sbin/kextunload -b $KEXTID"
        echo "$unloadCmd..."
        eval $unloadCmd || exit 1
    fi
}

function UnInstallVFSForGit()
{
    if [ -d "${VFSFORDIRECTORY}" ]; then
        rmCmd="sudo /bin/rm -Rf ${VFSFORDIRECTORY}"
        echo "$rmCmd..."
        eval $rmCmd || exit 1
    fi
    
    if [ -d "${PRJFSKEXTDIRECTORY}/$KEXTFILENAME" ]; then
        rmCmd="sudo /bin/rm -Rf ${PRJFSKEXTDIRECTORY}/$KEXTFILENAME"
        echo "$rmCmd..."
        eval $rmCmd || exit 1
    fi
    
    if [ -f "${LAUNCHDAEMONDIRECTORY}/$LOGDAEMONLAUNCHDFILENAME" ]; then
        unloadCmd="sudo launchctl unload -w ${LAUNCHDAEMONDIRECTORY}/$LOGDAEMONLAUNCHDFILENAME"
        echo "$unloadCmd..."
        eval $unloadCmd || exit 1
        rmCmd="sudo /bin/rm -Rf ${LAUNCHDAEMONDIRECTORY}/$LOGDAEMONLAUNCHDFILENAME"
        echo "$rmCmd..."
        eval $rmCmd || exit 1
    fi
    
    # Unloading Service LaunchAgent for each user
    # There will be one loginwindow instance for each logged in user, 
    # get its uid (this will correspond to the logged in user's id.) 
    # Then use launchctl bootstrap gui/uid to auto load the Service 
    # for each user.
    if [ -f "${LAUNCHAGENTDIRECTORY}/$SERVICEAGENTLAUNCHDFILENAME" ]; then
        for uid in $(ps -Ac -o uid,command | grep -iw "loginwindow" | awk '{print $1}'); do
            unloadCmd="sudo launchctl bootout gui/$uid ${LAUNCHAGENTDIRECTORY}/$SERVICEAGENTLAUNCHDFILENAME"
            echo "$unloadCmd..."
            eval $unloadCmd || exit 1
        done
        
        rmCmd="sudo /bin/rm -Rf ${LAUNCHAGENTDIRECTORY}/$SERVICEAGENTLAUNCHDFILENAME"
        echo "$rmCmd..."
        eval $rmCmd || exit 1
    fi
    
    if [ -s "${GVFSCOMMANDPATH}" ]; then
        rmCmd="sudo /bin/rm -Rf ${GVFSCOMMANDPATH}"
        echo "$rmCmd..."
        eval $rmCmd || exit 1
    fi
}

function ForgetPackage()
{
    if [ -f "/usr/sbin/pkgutil" ]; then
        forgetCmd="sudo /usr/sbin/pkgutil --forget $INSTALLERPACKAGEID"
        echo "$forgetCmd..."
        eval $forgetCmd
    fi
}

function Run()
{
    UnloadKext
    UnInstallVFSForGit
    ForgetPackage
    echo "Successfully uninstalled VFSForGit"
}

Run

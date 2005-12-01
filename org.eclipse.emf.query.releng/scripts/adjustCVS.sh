#!/bin/sh

# Adjusts the CVS for the build by#
# 	1. RTagging all source files
#	2. Creating the map file
#	3. Checking and tagging the mapping file

proj="query"

if [ $# -lt 10 ]; then
	echo "usage: adjustCVS.sh"
	echo "-baseDir          <directory where org.eclipse.emft.*.releng was checked out>"
	echo "-branch           <CVS branch of the files to be built>"
	echo "-projBranch       <CVS branch of the files to be built (eg., build_200409171617 instead of HEAD)>"
	echo "-projRelengBranch <CVS branch of org.eclipse.emft.*.releng>"
	echo "-buildTag         <the tag for the files of this build>"
	echo "-repoInfoFile     <The build configuration file>"
	echo "-eclipseURL       <The URL of the Eclipse driver to be used during the build.  The name of the file "
	echo "                   defines the OS and the WS>"
	echo "-tagBuild         <Optional: defines if the files are tagged - Values: true|false  - Default: true>"
	echo "-emfURL           <The URL of the EMF driver to be used during the build.>"
	echo "example: adjustCVS.sh -repoInfoFile ../buildConfig.properties -tagBuild true -baseDir /home/build/org.eclipse.emft.$proj.releng -branch HEAD -buildTag build_200402061550 -eclipseURL http://download.eclipse.org/downloads/drops/S-3.0M5-200311211210/eclipse-SDK-3.0M5-linux-gtk.zip"
	exit 1
fi

tagBuild='true'

# Create local variable based on the input
while [ "$#" -gt 0 ]; do
	case $1 in
		'-branch')
			branch=$2;
			shift 1
			;;
		'-projBranch')
			projBranch=$2;
			shift 1
			;;
		'-projRelengBranch')
			projRelengBranch=$2;
			shift 1
			;;
		'-eclipseURL')
			eclipseURL=$2;
			shift 1
			;;
		'-emfURL')
			emfURL=$2;
			shift 1
			;;
		'-baseDir')
			baseDir=$2;
			shift 1
			;;
		'-buildTag')
			buildTag=$2;
			shift 1
			;;
		'-tagBuild')
			tagBuild=$2;
			shift 1
			;;
		'-repoInfoFile')
			repoInfoFile=$2;
			shift 1
			;;
	esac
	shift 1
done

# Reading properties
scriptDir=`dirname $0`
cvsHost=`$scriptDir/readProperty.sh $repoInfoFile cvsHost`
cvsReadProtocol=`$scriptDir/readProperty.sh $repoInfoFile cvsReadProtocol`
cvsWriteProtocol=`$scriptDir/readProperty.sh $repoInfoFile cvsWriteProtocol`
cvsReadUser=`$scriptDir/readProperty.sh $repoInfoFile cvsReadUser`
cvsWriteUser=`$scriptDir/readProperty.sh $repoInfoFile cvsWriteUser`
cvsWriteRelengUser=`$scriptDir/readProperty.sh $repoInfoFile cvsWriteRelengUser`
cvsRep=`$scriptDir/readProperty.sh $repoInfoFile cvsRep`

# Setting environment variables
export CVS_RSH=ssh
export CVSROOT=:$cvsWriteProtocol:$cvsWriteUser@$cvsHost:$cvsRep
echo "CVSROOT: $CVSROOT"

projRelengBranchCmd="";
if [ "$projRelengBranch" = "HEAD" ]; then
	projRelengBranchCmd="";
elif [ x$projRelengBranch != x ]; then
	projRelengBranchCmd="-r $projRelengBranch";
elif [ $branch != HEAD ]; then
	projRelengBranchCmd="-r $branch"; # by default, if project build from R1_0_maintenance, use same tag for o.e.*.releng
fi
	
projBranchCmd="";
if [ "x$projBranch" != "x" ]; then
	projBranchCmd=" -r $projBranch"; # override for debugging
else
	projBranchCmd=" -r $branch"; # default 
fi

# RTagging source files
if [ $tagBuild != 'false' ]; then
	command="cvs -q rtag $projBranchCmd $buildTag"
	command=$command" org.eclipse.emft/$proj"
	$baseDir/scripts/executeCommand.sh "$command"
fi

# Creating the map file
command="perl $baseDir/scripts/createMapAndTestManifestFile.pl"
command=$command" $repoInfoFile"
command=$command" $baseDir/maps/$proj.map"
command=$command" $baseDir/templateFiles/$proj.map.template"
command=$command" $baseDir/testManifest.xml"
command=$command" $baseDir/templateFiles/testManifest.xml.template"
command=$command" $buildTag"
$baseDir/scripts/executeCommand.sh "$command"

# Creating the build.cfg file
command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/maps/build.cfg"
command=$command" $baseDir/templateFiles/build.cfg.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"

# Creating the build.properties for each type of packaging
command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/sdk/build.properties"
command=$command" $baseDir/templateFiles/build.properties.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"

command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/$proj/runtime/build.properties"
command=$command" $baseDir/templateFiles/build.properties.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"

command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/examples/build.properties"
command=$command" $baseDir/templateFiles/build.properties.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"
	
command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/tests/build.properties"
command=$command" $baseDir/templateFiles/build.properties.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"

command="perl $baseDir/scripts/createConfigurationFiles.pl"
command=$command" $baseDir/$proj/doc/build.properties"
command=$command" $baseDir/templateFiles/build.properties.template"
command=$command" $eclipseURL"
command=$command" $emfURL"
$baseDir/scripts/executeCommand.sh "$command"


# Checking in and tagging the files
if [ $tagBuild != 'false' ]; then
	currentDir=$PWD
	cd $baseDir
	$baseDir/scripts/executeCommand.sh "cvs -q ci -m $buildTag"
	cd $currentDir
	$baseDir/scripts/executeCommand.sh "cvs -d :$cvsWriteProtocol:$cvsWriteRelengUser@$cvsHost:$cvsRep -q rtag $projRelengBranchCmd $buildTag org.eclipse.emft/releng/common"
	$baseDir/scripts/executeCommand.sh "cvs -d :$cvsWriteProtocol:$cvsWriteRelengUser@$cvsHost:$cvsRep -q rtag $projRelengBranchCmd $buildTag org.eclipse.emft/releng/$proj"
fi
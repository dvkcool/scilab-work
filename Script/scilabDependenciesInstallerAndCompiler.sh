#!/bin/sh
# shellcheck disable=SC2155
# shellcheck disable=SC2164
# shellcheck disable=SC1091
# shellcheck disable=SC1117

# Checking if user has root access
if [[ $EUID -ne 0 ]]; then
   echo "You must run this script with root permissions."
   exit 0
fi

# Config
OSXVersion="$(sw_vers -productVersion | cut -f -2 -d .)"
DarwinVersion="$(uname -r | cut -d. -f1)"
XcodeURL="macappstore://itunes.apple.com/us/app/xcode/id497799835?mt=12"

Jvers="1.6"

FinkVersion="0.43.0"
FinkMD5Sum="cbeb5c105cb83e97db073a6143d262e9"
FinkOutDir="fink"
FinkDirectorY="${FinkOutDir}-${FinkVersion}"
FinkFileName="${FinkDirectorY}.tar.gz"
FinkSourceDLP="http://downloads.sourceforge.net/fink/${FinkFileName}"

XQuartzVersion="2.7.11"
XQuartzMD5Sum="8e9dbfe2717c8d74c262b3a963597898"
XQuartzPKGPath="XQuartz.pkg"
XQuartzFileName="XQuartz-${XQuartzVersion}.dmg"
XQuartzSourceDLP="https://dl.bintray.com/xquartz/downloads/${XQuartzFileName}"


function fetchBin {

	local MD5Sum="$1"
	local SourceDLP="$2"
	local FileName="$3"
	local DirectorY="$4"
	local OutDir="$5"

	# Checks
	if [[ -d "${OutDir}" ]] && [[ -f "${FileName}" ]]; then
		# Check to make sure we have the right file
		local MD5SumLoc="$(cat "${OutDir}/.MD5SumLoc" 2>/dev/null || echo "")"
		if [ "${MD5SumLoc}" != "${MD5Sum}" ]; then
			echo "warning: Cached file is outdated or incorrect, removing" >&2
			rm -fR "${DirectorY}" "${OutDir}"
			MD5SumFle="$(md5 -q "${FileName}")"
			if [ "${MD5SumFle}" != "${MD5Sum}" ]; then
				rm -fR "${FileName}"
			fi
		else
			# Do not do more work then we have to
			echo "${OutDir} already exists, skipping" >&2
			return
		fi
	elif [[ -f "${FileName}" ]]; then
		MD5SumFle="$(md5 -q "${FileName}")"
		if [ "${MD5SumFle}" != "${MD5Sum}" ]; then
			rm -fR "${FileName}"
		fi
	fi

	# Fetch
	if [ ! -r "${FileName}" ]; then
		echo "Fetching ${SourceDLP}"
		if ! curl -Lfo "${FileName}" --connect-timeout "30" "${SourceDLP}"; then
			echo "error: Unable to fetch ${SourceDLP}" >&2
			exit 1
		fi
	else
		echo "${FileName} already exists, skipping" >&2
	fi

	# Check our sums
	local MD5SumLoc="$(md5 -q "${FileName}")"
	if [ -z "${MD5SumLoc}" ]; then
		echo "error: Unable to compute md5 for ${FileName}" >&2
		exit 1
	elif [ "${MD5SumLoc}" != "${MD5Sum}" ]; then
		echo "error: MD5 does not match for ${FileName}" >&2
		exit 1
	fi

	# Unpack
	local ExtensioN="${FileName##*.}"
	if [[ "${ExtensioN}" = "gz" ]] || [[ "${ExtensioN}" = "tgz" ]]; then
		if ! tar -zxf "${FileName}"; then
			echo "error: Unpacking ${FileName} failed" >&2
			exit 1
		fi
	elif [ "${ExtensioN}" = "bz2" ]; then
		if ! tar -jxf "${FileName}"; then
			echo "error: Unpacking ${FileName} failed" >&2
			exit 1
		fi
	elif [ "${ExtensioN}" = "dmg" ]; then
		return
	else
		echo "error: Unable to unpack ${FileName}" >&2
		exit 1
	fi

	# Save the sum
	echo "${MD5SumLoc}" > "${DirectorY}/.MD5SumLoc"

	# Move
	if [ ! -d "${DirectorY}" ]; then
		echo "error: Can't find ${DirectorY} to rename" >&2
		exit 1
	else
		mv "${DirectorY}" "${OutDir}"
	fi
}

# Make sure we are in the right place
cd "${HOME}/Downloads"

# Version check
if [[ "${DarwinVersion}" -lt "13" ]]; then
	echo "This script is for use on OS 10.9+ only."
	exit 1
fi

# Intro Explanation
cat > "/dev/stderr" << EOF
This script will automate the installation of fink, its prerequisets
and help out a bit with initial setup; to do this an internet
connection is required.

Before fink can be installed you need to have java, the Command Line
Tools, XQuartz and accepted the xcode licence. Additionally you may
wish to install the full Xcode app.

After this script detects one of these requirements to be missing it
will attempt to install it for you; in most cases this will mean the
script will exit while it waits for the install to finish. After an
install has completed just run this script again and it will pick up
where it left off.

EOF

# Handle existing installs
if [ -d "/sw" ]; then
	FinkExisting="1"
	cat > "/dev/stderr" << EOF
It looks like you already have fink installed; if it did not finish or
you are upgrading we will move it aside to /sw.old so you can delete it
later if you like; otherwise you may want to exit.

EOF
fi

if ! read -n1 -rsp $'Press any key to continue or ctrl+c to exit.\n'; then
	exit 1
fi

if [ "${FinkExisting}" = "1" ]; then
	if ! sudo mv /sw /sw.old; then
		clear
		cat > "/dev/stderr" << EOF
Could not move /sw to /sw.old; you may need to delete one or both these
yourself.
EOF
		exit 1
	fi
fi


# Check for Xcode
clear
echo "Checking to see if xcode is installed..." >&2
XcodePath="$(mdfind kMDItemCFBundleIdentifier = "com.apple.dt.Xcode")"
if [ ! -z "${XcodePath}" ]; then
	echo "Xcode is installed, setting up the defaults..." >&2
	sudo xcode-select -switch "${XcodePath}/Contents/Developer"
else
	echo "You do not have Xcode installed." >&2
	read -rp $'Do you want to install xcode?\n[N|y] ' choice
	if [[ "${choice}" = "y" ]] || [[ "${choice}" = "Y" ]]; then
		open "${XcodeURL}"
		exit 0
	fi
fi

# Check for java
clear
echo "Checking for Java..." >&2
if ! /usr/libexec/java_home -Fv "${Jvers}+"; then
	java -version > /dev/null 2>&1
	echo "Please install the JDK not the JRE, since we need it to build things against; please rerun this script when it finishes installing." >&2
	exit 0
fi
echo "Found version $(java -version > /dev/null 2>&1 | grep 'version' | sed -e 's:java version ::' -e 's:"::g')." >&2

# Check for Command Line Tools
clear
echo "Checking for the Xcode Command Line Tools..." >&2
if ! pkgutil --pkg-info=com.apple.pkg.CLTools_Executables; then
	echo "The Xcode Command Line Tools are installing, please rerun when it finishes." >&2
	xcode-select --install
	exit 0
fi

# Check for XQuartz
clear
echo "Checking for XQuartz..." >&2
if ! pkgutil --pkg-info=org.macosforge.xquartz.pkg; then
	echo "XQuartz is not installed, fetching..." >&2
	fetchBin "${XQuartzMD5Sum}" "${XQuartzSourceDLP}" "${XQuartzFileName}" "-" "-"
	echo "Mounting the XQuartz disk..." >&2
	hdiutilOut="$(hdiutil mount "${XQuartzFileName}" 2>/dev/null | tr -d "\t" | grep -F '/dev/disk' | grep -Fv 'GUID_partition_scheme')"
	XQuartzVolPath="$(echo "${hdiutilOut}" | sed -E 's:(/dev/disk[0-9])(s[0-9])?( +)?(Apple_HFS)?( +)::')"
	echo "Starting the XQuartz install; please rerun this script when it finishes." >&2
	open "${XQuartzVolPath}/${XQuartzPKGPath}"
	exit 0
fi

# Check the xcode licence
if [[ ! -f /Library/Preferences/com.apple.dt.Xcode.plist ]] && [[ ! -z "${XcodePath}" ]]; then
	choice=""
	while [[ ! "${choice}" = "1" ]] || [[ ! "${choice}" = "2" ]] || [[ ! "${choice}" = "3" ]]; do
		clear
		cat > "/dev/stderr" << EOF
You need to accept the xcode licence to continue.
You can:
[1] Read the licence and accept it. (Default)
[2] Accept the licence without reading it.
[3] Quit.
EOF
		read -rp $'[1|2|3] ' choice
		if [ -z "${choice}" ]; then
			choice="1"
		fi
		case "${choice}" in
			1) sudo xcodebuild -license ;;
			2) sudo xcodebuild -license accept ;;
			3) exit 0 ;;
			*) echo "Not a valid choice." >&2 ;;
		esac
	done
fi

# Get Fink
clear
echo "Fetching Fink..." >&2
fetchBin "${FinkMD5Sum}" "${FinkSourceDLP}" "${FinkFileName}" "${FinkDirectorY}" "${FinkOutDir}"
# clear
# read -rp $'Do you want to use the binary distribution instead of having to build all packages locally?\n[Y|n] ' choice
# if [[ "${choice}" = "y" ]] || [[ "${choice}" = "Y" ]] || [[ -z "${choice}" ]]; then
# 	UseBinaryDist="1"
# fi

# Build Fink
clear
cat > "/dev/stderr" << EOF
We are about to start building Fink; this may take a bit, so feel free
to grab a cup of you favorite beverage while you wait.
EOF

if ! read -n1 -rsp $'Press any key to continue or ctrl+c to exit.\n'; then
	exit 1
fi

clear
cd "${FinkOutDir}"

if ! ./bootstrap /sw; then
	exit 1
fi

# Set up bindist
# shellcheck disable=SC2154
if [ "${UseBinaryDist}" = "1" ]; then
	clear
	echo "Activating the Binary Distribution..." >&2
	sudo rm /sw/etc/fink.conf.bak
	sudo mv /sw/etc/fink.conf /sw/etc/fink.conf.bak
	sed -e 's|UseBinaryDist: false|UseBinaryDist: true|' "/sw/etc/fink.conf.bak" | sudo tee "/sw/etc/fink.conf"

	if grep -Fqx 'bindist.finkmirrors.net' "/sw/etc/apt/sources.list"; then
		# Fix wrong address.
		sudo rm "/sw/etc/apt/sources.list.finkbak"
		sudo mv "/sw/etc/apt/sources.list" "/sw/etc/apt/sources.list.finkbak"
		sed -e 's:finkmirrors.net:finkproject.org:g' "/sw/etc/apt/sources.list.finkbak" | sudo tee "/sw/etc/apt/sources.list"
	elif ! grep -Fqx 'http://bindist.finkproject.org/' "/sw/etc/apt/sources.list"; then
		sudo tee -a "/sw/etc/apt/sources.list" << EOF

# Official bindist see http://bindist.finkproject.org/ for details.
deb http://bindist.finkproject.org/${OSXVersion} stable main

EOF
	fi
fi

# Set up paths
clear
echo "Setting up Fink paths..." >&2
/sw/bin/pathsetup.sh

# First selfupdate
source /sw/bin/init.sh
clear
cat > "/dev/stderr" << EOF
Now the last thing we will do is run 'fink selfupdate' for the first
time.

It will ask you to choose a method; unless you have a really picky
firewall you probaly want to choose rsync.

EOF

if ! read -n1 -rsp $'Press any key to continue or ctrl+c to exit.\n'; then
	exit 1
fi

fink selfupdate
clear

echo "Installing Scilab dependencies with fink"

. /sw/bin/init.sh

# An array containing list of packages to install
declare -a packages=("suitesparse"
                      "fftw3"
                      "libmatio2"
                      "libmatio2-shlibs"
                      "hdf5.9" "hdf5.9-shlibs"
                      "libpcre1"
                      "ant"
                      "gettext-bin"
                      "gettext-tools"
                      "arpack-ng"
                      "pkgconfig"
                      "libcurl4"
                      "libmatio2")

# Installing each package one by one
for i in "${packages[@]}"
do
   clear
   echo " Installing  $i"
   fink install $i
done

# A variable to count number of unistalled packages
count=0

# A variable to store list of installed packages
installed=""

# A variable to store list of uninstalled packages
ninstalled=""

# A variable to store a list of all packages installed through fink
listi=$(fink list -i)


for i in "${packages[@]}"
do
# checking if listi contains a package specified
   if [ -z "${listi##*$i*}" ] ; then
     installed="$installed \n $i"
   else
     # Increasing count, if its uninstalled
     count=`expr $count + 1`
     ninstalled="$ninstalled \n $i"
   fi
done

# Clearing screen
clear
echo  "List of installed packages : $installed \n\n"

# If count > 0 then there is a package which is not installed, i.e. Not ready to compile yet
if [ $count -gt 0 ] ; then
  echo  "Following packages were not installed: $ninstalled\n\n Please install them manually"
else
  # All packages are installed and ready to compile
  echo   "Congratulations everything is perfectly setup to compile Scilab\n\n"
fi

# Deleting scilab folder if already present
sudo rm -rf scilab

# Cloning the base repository
git clone git://git.scilab.org/scilab

# Performing svn checkout
cd scilab/scilab

svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/bin bin
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/lib lib
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/thirdparty thirdparty
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/include include
svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/java java



# Checking out the branch
cd ..

branch_default="6.0"
read -p "Please enter your choice of branch[$branch_default]: " branch
branch="${branch:-$branch_default}"

# Git checkout
git checkout $branch

# Going for compilation

cd scilab

# Initialins fink again just to be sure
. /sw/bin/init.sh
parameters=""
# Asking about Modelica/ ocaml
read -p "Do you want to compile with ocaml [y/n]" t

if [ "$t" = "y" ]; then
  sudo fink install ocaml
  listi=$(fink list -i)
  i="ocaml"
  # checking if listi contains ocaml
     if [ -z "${listi##*$i*}" ] ; then
       echo "ocaml installed"
     else
       echo "ocaml not installed, Please install it manually and rerun the script."
       exit 0
     fi
 else
  parameters=" $parameters  --without-modelica"
fi

# Do you want to specify other parameters while compilation
read -p "Do you want to specify other parameters while compilation [y/n]" t
if [ "$t" = "y" ]; then
  echo "Please enter the other paramters: "
  read t
  parameters=" $parameters $t"
fi

# jdkpath_default=$(/usr/libexec/java_home)

#read -p "Please enter your jdk path [$jdkpath_default]: " jdkpath
#jdkpath="${jdkpath:-$jdkpath_default}"

#echo "Copying third party lib from Scilab to jre folder"
# Changing to third party lib folder
#cd ./lib/thirdparty

# Recursively copying files
#cp -R *  $jdkpath/jre/lib/
#cd ../..

# Getting full path of current directory
current_dir=$(pwd)
DYLD_LIBRARY_PATH="$current_dir/lib/thirdparty"
export DYLD_LIBRARY_PATH

# Compiling with paramerters specified by users
./configure --without-openmp --without-tk --with-eigen_include=`pwd`/lib/Eigen/includes $parameters && make

# Installing scilab
make install

# Running scilab
echo "Congratulations Scilab is successfully installed. \n\n To launch Scilab just type scilab in terminal".


exit 0

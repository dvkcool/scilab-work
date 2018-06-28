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


# Performing svn checkout
cd scilab/scilab
# git checkout 6.0

# svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/bin bin
# svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/lib lib
# svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/thirdparty thirdparty
# svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/include include
# svn checkout --username anonymous --password Scilab svn://svn.scilab.org/scilab/trunk/Dev-Tools/SE/Prerequirements/macosx/java java



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

jdkpath_default=$(/usr/libexec/java_home)

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

# Creating a .app for Mac including folder for resources and plugins(including thirdparty libs and  jdk).
mkdir -p Scilab.app/Contents/MacOS/ Scilab.app/Contents/Resources/ Scilab.app/Contents/MacOS/thirdparty/ Scilab.app/Contents/MacOS/thirdparty/java/

# Copying Info.plist to app
cp ./etc/Info.plist ./Scilab.app/Contents/

# Copying the icon
cp  ./desktop/images/icons/puffin.icns ./Scilab.app/Contents/Resources/


# Copying the JDK
cp -R /Library/Java/JavaVirtualMachines/jdk1.8.0_171.jdk/* ./Scilab.app/Contents/MacOS/thirdparty/java/

# Copying thirdparty libraries to the jdk(Additional)
cp -R ./lib/thirdparty/* ./Scilab.app/Contents/MacOS/thirdparty/java/Contents/Home/jre/lib/

# Copying thirdparty jars
cp -R ./thirdparty/* ./Scilab.app/Contents/MacOS/thirdparty/


# Making dynamic link
cd ./Scilab.app/Contents/MacOS/thirdparty/java/Contents/Home
sudo ln -s ./jre/lib/server/libjvm.dylib libserver.dylib
cd ../../../../../../..

# Making dynamic link- putting a link in COntents too, sometimes it looks in Contents too.
cd ./Scilab.app/Contents/MacOS/thirdparty/java/Contents/
sudo ln -s ./Home/jre/lib/server/libjvm.dylib libserver.dylib
cd ../../../../../..

# Compiling with paramerters specified by users
 ./configure  --without-openmp --prefix=`pwd`/Scilab.app/Contents/MacOS/ --without-tk --with-eigen_include=`pwd`/lib/Eigen/includes  --with-jdk=`pwd`/Scilab.app/Contents/MacOS/thirdparty/java/Contents/Home $parameters && make
# ./configure  --without-openmp  --without-tk --with-eigen_include=`pwd`/lib/Eigen/includes $parameters --with-jdk=`pwd`/Scilab.app/Contents/MacOS/thirdparty/java/Contents/Home && make
# Installing scilab
make install

# Removing a depreciated library
 rm Scilab.app/Contents/MacOS/thirdparty/java/Contents/Home/jre/lib/libjfxmedia.dylib


# Putting read write permissions in jdk
 chmod -R +w Scilab.app/Contents/MacOS/thirdparty/java

# Signing all the jars and dylib
 find Scilab.app/Contents/ -type f \( -name "*.jar" -or -name "*.dylib" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing executables in bin folder
 find Scilab.app/Contents/MacOS/bin/ -type f \( -name "*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing header files (.h, .hxx, .hpp) and html files too
 find Scilab.app/Contents/ -type f \( -name "*.h*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing .pc, .pf files
 find Scilab.app/Contents/ -type f \( -name "*.p*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing -la files
 find Scilab.app/Contents/MacOS/lib/scilab/ -type f \( -name "*.la*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing LICENSE files
 find Scilab.app/Contents/ -type f \( -name "*.LICENSE*"  -or -name "*LICENSE*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing xml and xsl  files
 find Scilab.app/Contents/ -type f \( -name "*.xml*" -or -name "*.xsl" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing Java files
 find Scilab.app/Contents/ -type f \( -name "*.java*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing properties files
 find Scilab.app/Contents/ -type f \( -name "*.properties*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing perl scripts (.pl files)
 find Scilab.app/Contents/ -type f \( -name "*.pl*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing text files and README too - I know its too much but codesign won't accept without txt files signed too.
 find Scilab.app/Contents/ -type f \( -name "*.txt*" -or -name "*README*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing antlr and CSS files
 find Scilab.app/Contents/ -type f \( -name "*.antlr*" -or -name "*.css*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing png and gif too
 find Scilab.app/Contents/ -type f \( -name "*.png*" -or -name "*.gif" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing options and packages executable in thirdparty/checkstyle/site/apidocs
 find Scilab.app/Contents/MacOS/thirdparty/checkstyle/site/apidocs/ -type f \( -name "options" -or -name "*package*" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing jilib files
 find Scilab.app/Contents/ -type f \( -name "*.jnilib" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing data files
 find Scilab.app/Contents/ -type f \( -name "*.data" \) -exec codesign --verbose -f -s "Mac Developer: Divyanshu Kumar " {} \;

# Signing the main app
 codesign -v -f -s "Mac Developer: Divyanshu Kumar "  Scilab.app

# moving the app to app folder
mv Scilab.app ./create-dmg/Scilab.app

./create-dmg --window-size 381 290 \
--background backimg.png \
 --icon-size 48 --volname "Scilab" \
 --app-drop-link 280 105 \
 --icon "Scilab.app" 100 105 \
 ScilabInstaller.dmg \
 Scilab.app

 # Signing the main dmg installer
 codesign -v -f -s "Mac Developer: Divyanshu Kumar " ScilabInstaller.dmg

echo "Congratulations dmg is ready"


exit 0

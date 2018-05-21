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

# Compiling the default
./configure --without-openmp --without-tk --without-modelica --with-eigen_include=`pwd`/lib/Eigen/includes && make

# Installing scilab
make install

# Running scilab
echo "Congratulations Scilab is successfully installed. \n\n To launch Scilanb just type scilab in terminal".


exit 0

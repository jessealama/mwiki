#!/bin/bash
# usage $1 = repo-directory; $2=full path xsl4mizar directory ; $3 full path mwiki directory
REPO=$1
XSL4MIZ=$2
MWIKI=$3
OLDMIZFILES=$MIZFILES

MIZBINARIES="absedt accom addfmsg checkvoc chklab clearenv.pl constr edtfile errflag exporter findvoc inacc irrths irrvoc lisppars listvoc makeenv mglue miz2abs miz2prel mizf msplit prune.mizar ratproof relinfer reliters relprem remflags renthlab revedt revf transfer trivdemo verifier";

if [ -z $MIZBIN ]; then
    MIZBIN=$MIZFILES/bin;
else
    MIZBIN=$MIZBIN;
fi

if [ -e $REPO ]; then
    echo "Target repository $REPO already exists; overwriting anyway...";
fi
mkdir -p $REPO

cp -a $MIZFILES/mml $REPO/mml
mkdir -p $REPO/prel
cp -p $MIZFILES/prel/h/hidden.* $REPO/prel
cp -p $MIZFILES/prel/*/*.dre $REPO/prel
cp  $MIZFILES/mml.* $REPO
cp  $MIZFILES/mizar.* $REPO

mkdir $REPO/bin
for binary in $MIZBINARIES; do
    cp -a $MIZBIN/$binary $REPO/bin/$binary;
done

mkdir $REPO/xsl
cp $XSL4MIZ/addabsrefs.xsl $REPO/xsl
cp $XSL4MIZ/miz.xsl $REPO/xsl
cp $XSL4MIZ/evl2dep.xsl $REPO/xsl

mkdir $REPO/.perl
cp $XSL4MIZ/mkxmlhead.pl $REPO/.perl
cp $MWIKI/mizar.pm $REPO/.perl
cp $MWIKI/Makefile.repo $REPO/Makefile

cd $REPO
git init
cp $MWIKI/mml-gitignore .gitignore
mkdir -p .git/hooks
cp $MWIKI/pre-commit .git/hooks
cp $MWIKI/post-commit .git/hooks
git add .

echo "Making the deps...here we go...";
MMLLAR=`cat mml.lar`;
cd mml
touch hidden-prel
cp  $MWIKI/Makefile-depsrepo Makefile
export MIZFILES=$REPO
make evls
make deps
echo "That was fun.  Let's make the xml!";
cd ..
make xmlvrfs
make prels
make absrefs
make htmls

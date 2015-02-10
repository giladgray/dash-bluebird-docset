DIR=../Dash-User-Contributions/docsets/Bluebird

# recreate directory
rm -r $DIR
mkdir $DIR

# copy docset files
cp ./bluebird.tgz ./docset.json ./bluebird.docset/icon.png ./bluebird.docset/icon@2x.png $DIR/
cp CONTRIB.md $DIR/README.md

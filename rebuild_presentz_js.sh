cd ../presentz.js
cake build
rm -rf ../presentz.org/public/assets/js/presentz*.js
cp dist/presentz-1.2.2.js ../presentz.org/public/assets/js/
cd -
sed -i 's/presentz-[0-9].[0-9].[0-9]/presentz-1.2.2/g' ./assets.coffee
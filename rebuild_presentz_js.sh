cd ../presentz.js
cake build
rm ../presentz.org/public/assets/js/presentz*.js
cp dist/presentz-1.3.0.js ../presentz.org/public/assets/js/
cd -
sed -i 's/presentz-[0-9].[0-9].[0-9]/presentz-1.3.0/g' ./assets.coffee
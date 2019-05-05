cd server
npm install
openssl req -nodes -new -x509 -keyout server.key -out server.cert
node index.js &
cd ..
cd client
swift package generate-xcodeproj
swift test
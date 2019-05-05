cd server
npm install
openssl req -nodes -new -x509 -keyout server.key -out server.cert
openssl x509 -in server.cert -outform der -out /tmp/server.der
node index.js &
cd ..
cd client
swift package generate-xcodeproj
swift test

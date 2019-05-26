cd server
npm install
openssl genrsa -out server.key 2048
openssl req -new -out server.csr -key server.key -config openssl.cnf
openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.cert -extensions v3_req -extfile openssl.cnf
#openssl pkcs12 -export -in server.cert -inkey server.key -out server.p12
openssl x509 -in server.cert -outform der -out server.der
cp server.der /tmp
node index.js &
cd ..
cd client
swift package generate-xcodeproj
swift test

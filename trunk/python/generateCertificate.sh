openssl genrsa -out privkey.pem 1024
openssl req -new -key privkey.pem -out cert.csr
openssl x509 -req -days 3650 -in cert.csr -signkey privkey.pem -out newcert.pem
( openssl x509 -in newcert.pem; cat privkey.pem ) > server.pem
ln -s server.pem `openssl x509 -hash -noout -in server.pem`.0

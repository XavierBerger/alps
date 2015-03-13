# Secure sever acess with SSL #
alps server can use SSL to secure the communication.
It is required to add certificate into certs directory and start alps with the -s parameter.


# How to generate certificate #

To generate a certificate, execute the following commands

```
openssl req -config demoCA/openssl.cnf \
        -new -days 365 -newkey rsa:1024 -x509 \
        -keyout demoCA/certs/server-key-with-password.pem -out demoCA/certs/server-cert.pem

openssl rsa -in demoCA/certs/server-key-with-password.pem -out demoCA/certs/server-key.pem
```
# Technologies use
MongoDB + ExpressJS + SocketIO + SwiftUI

## Server
1. Install docker desktop https://www.docker.com/products/docker-desktop
2. Login Docker
3. `docker-compose up -build`
4. Check `http://localhost:8081` for DB GUI and `http://localhost` for apis (cannot get \)

> http://localhost/create_code?username=1
> http://localhost/make_payment?store_id=1&amount=1234&code=9000013685385798

## Client
1. Build with Xcode
2. Enter any username then connect to `localhost`
3. Refresh to get new bar code
4. Try `/make_payment` in url to finish current code
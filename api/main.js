const express = require("express")();
const cors = require("cors");
const http = require("http").createServer(express);
const io = require("socket.io")(http);
const { MongoClient } = require("mongodb");
var ObjectId = require('mongodb').ObjectId;

const client = new MongoClient("mongodb://root:example@mongo:27017/", {useNewUrlParser: true, useUnifiedTopology: true});

express.use(cors());

var users;
var codes;
var payments;

const sessionsMap = {};

io.on("connection", (socket) => {
    socket.on("join", async (username) => {
        try {
            let user = await users.findOne({"username": username});
            if(!user) {
                user = {"username": username}
                await users.insertOne(user)
            }
            
            sessionsMap[user._id] = socket.id;
            socket.username = user.username;
            socket.emit("joined", user);
        } catch (e) {
            console.error(e);
        }
    });

    socket.on("disconnect", (reason) => {
        // ...
    });
});

express.get("/hello", async(request, response) => {
    response.sendStatus(500);
})

express.get("/create_code", async (request, response) => {
    try {
        let user_id = request.query.user_id

        if (!user_id) {
            response.json({"result": false, "msg": "User Id not found"})
            return
        }

        if (user_id.length != 24) {
            response.json({"result": false, "msg": "Invalid user id"})
            return
        }

        let uid = new ObjectId(user_id)
        let user = await users.find({_id: uid})

        if (!user) {
            response.json({"result": false, "msg": "User not found"});
            return
        }

        let code = createRandomCode(user_id);
    
        let minutes = 5
        let date = new Date((new Date()).getTime() + minutes * 60000);
    
        await codes.updateOne({"user_id": user_id, "is_active": true}, {$set:{
            "is_active": false
        }})
    
        /// associate code with user
        await codes.insertOne({
            "code": code,
            "user_id": user_id,
            "expires_date": date,
            "is_active": true,
            "is_paid": false,
        })
    
        response.json({"code": code, "expires_date": date.toISOString(), "user_id": user_id})
    } catch (e) {
        console.error(e);
    }
    
});

express.get("/make_payment", async (request, response) => {
    try {
        let code = request.query.code
        let amount = request.query.amount
        let store = request.query.store_id
        let activeCode = await codes.findOne({"code": code})

        if (!activeCode) {
            response.json({"result": false, "msg": "Invalid code"});
            return
        }

        if (!activeCode.is_active) {
            response.json({"result": false, "msg": "Code " + code + " is invalid"});
            return
        }

        if (activeCode.is_paid) {
            response.json({"result": false, "msg": "Code " + code + " is paid"});
            return
        }

        let expires = activeCode.expires_date

        if (expires < Date.now()) {
            response.json({"result": false, "msg": "Invalid code"});
            return
        }

        let userID = activeCode.user_id

        /// update code to expired and push new code to client
        await codes.updateOne({"code": code}, {$set:{
            "is_active": false,
            "is_paid": true
        }})

        let newPayment = {
            "code": code,
            "store_id": store,
            "amount": amount,
            "user_id": userID,
            "date": (new Date())
        }

        /// add payment
        let inserted = await payments.insertOne(newPayment)

        response.json(
            {"result": true, "payment_id": inserted.insertedId}
        );

        const receiverId = sessionsMap[userID];
        io.to(receiverId).emit("payment", newPayment);

    } catch (e) {
        console.error(e);
    }    
});


http.listen(80, async () => {
    try {
        await client.connect();
        users = client.db("payment").collection("user");
        codes = client.db("payment").collection("codes");
        payments = client.db("payment").collection("payments");

        console.log("Listening on port :%s...", http.address().port);
    } catch (e) {
        console.error(e);
    }
});

function createRandomCode(userId) {
    return "900001" + makeid(2) + makeid(8);
}

function makeid(length) {
    var result           = '';
    var characters       = '0123456789';
    var charactersLength = characters.length;
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength));
   }
   return result;
}
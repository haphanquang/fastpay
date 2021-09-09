const utils = require('./../utils.js');
var ObjectId = require('mongodb').ObjectId;

module.exports = function(express, io, mongo) {
    var users = mongo.db("payment").collection("user");
    var codes = mongo.db("payment").collection("codes");
    var payments = mongo.db("payment").collection("payments");

    express.get("/v1/hello", async(request, response) => {
        response.sendStatus(500);
    })
    
    express.get("/v1/create_code", async (request, response) => {
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
    
            let code = utils.createRandomCode(user_id);
        
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
    
    express.get("/v1/make_payment", async (request, response) => {
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
                response.json({"result": false, "msg": "Expired code"});
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
                {"result": true, "payment_id": inserted.insertedId, "code": code}
            )
    
            const receiverId = utils.getSocketForUser(userID)
            io.to(receiverId).emit("payment", newPayment);
    
        } catch (e) {
            console.error(e);
        }    
    });
}
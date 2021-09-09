const sessionsMap = {}

function createRandomCode(userId, version = "1") {
    return "90000" + version + makeid(2) + makeid(8)
}

function makeid(length) {
    var result           = ''
    var characters       = '0123456789'
    var charactersLength = characters.length
    for ( var i = 0; i < length; i++ ) {
      result += characters.charAt(Math.floor(Math.random() * charactersLength))
   }
   return result
}

function addSession(userId, socketId) {
    sessionsMap[userId] = socketId
}

function getSocketForUser(userId) {
    return sessionsMap[userId]
}

exports.createRandomCode = createRandomCode
exports.makeid = makeid
exports.addSession = addSession
exports.getSocketForUser = getSocketForUser
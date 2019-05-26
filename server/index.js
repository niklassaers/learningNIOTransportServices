const fs = require('fs')
const https = require('https')
const express = require('express')
const app = express()

app.get('/', (req, res) => {
  res.send('Hello HTTPS!')
})

https.createServer({
  key: fs.readFileSync('server.key'),
  cert: fs.readFileSync('server.cert')
}, app).listen(4433, () => {
  console.log('Listening...')
})

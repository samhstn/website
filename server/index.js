import express from 'express'
import ejs from 'ejs'
import cors from 'cors'
import { marked } from 'marked'
import S3 from './s3.js'
import fetch from 'node-fetch'
import 'dotenv/config'
const { PORT, BUCKET_NAME = 'samhstn-website', NODE_ENV } = process.env

const s3 = new S3({ bucketName: BUCKET_NAME })

const app = express()

const hostname = 'localhost'
const port = PORT ?? 8080

app.engine('.html', ejs.__express)
app.set('view engine', 'ejs')
app.set('views', ['views', 'projects'])

if (NODE_ENV === 'development') {
  app.use(cors())
}

app.use(express.static('public'))
if (NODE_ENV === 'development') {
  app.get('/assets/*', (req, res) => {
    try {
      const key = req.params[0]
      s3.stream(`assets/${key}`, res)
    } catch (error) {
      res.status(500).json({ error: error.message })
    }
  })
} else {
  app.use('/assets', express.static('assets'))
}
app.use(express.json())

app.get('/', (req, res) => {
  res.render('home.html')
})

app.get('/status', (req, res) => {
  res.json({
    status: 'ok',
    environment: NODE_ENV
  })
})

app.get('/blog', async (req, res) => {
  if (NODE_ENV == 'production') {
    try {
      const response = await fetch(BUCKET_URL)
      const text = await response.text()
      res.send(text)
    } catch (error) {
      res.status(500).json({ error: error.message })
    }
  }
  res.render('blog.html')
})

app.get('/projects', async (req, res) => {
  res.render('projects.html')
})

app.get('/projects/:project', async (req, res) => {
  const { project } = req.params

  res.render(`projects/${project}`)
})

app.get('/blog/:file', async (req, res) => {
  try {
    const { file } = req.params
    console.log('fffffff', file)
    res.send('hello' + file)
  } catch (error) {
    res.status(500).json({ error: error.message })
  }
})

app.listen(port, () => {
  console.log(`Server running at http://${hostname}:${port}/`)
})

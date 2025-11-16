// src/index.ts
import Fastify from 'fastify'
const app = Fastify()

app.get('/healthz', async () => ({status: 'ok'}))
app.get('/', async () => ({message: 'hello world'}))

app.listen({port: 3000}).then(() => {
  console.log('Server listening on port 3000')
})
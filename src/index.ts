// src/index.ts
import { PrismaClient } from '@prisma/client'
import Fastify from 'fastify'
const app = Fastify()

app.get('/healthz', async () => ({status: 'ok'}))
app.get('/', async () => ({message: 'hello world'}))

app.listen({port: 3000}).then(() => {
  console.log('Server listening on port 3000')
})

app.post('/users', async (req) => {
  const prisma = new PrismaClient()
  const user = await prisma.user.create({
    data: { email: 'test@example.com' }
  })
  return user
})

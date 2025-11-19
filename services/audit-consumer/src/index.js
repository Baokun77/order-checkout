const { Kafka } = require('kafkajs');
const { prisma } = require('./db/client');

const kafka = new Kafka({
  clientId: 'audit-service',
  brokers: ['localhost:9092'],
});

const consumer = kafka.consumer({ groupId: 'audit-group' });
const producer = kafka.producer();

async function handleMessage(message, retries = 3) {
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const event = JSON.parse(message.value.toString());
      console.log(`Processing event (attempt ${attempt}/${retries}):`, event);

      await prisma.auditLog.create({
        data: {
          orderId: event.orderId,
          payload: event,
          createdAt: new Date(),
        },
      });

      console.log('Successfully processed event:', event.orderId);
      return;
    } catch (err) {
      console.error(`Attempt ${attempt}/${retries} failed:`, err.message);

      if (attempt === retries) {
        console.error('All retries exhausted, sending to DLQ');
        try {
          await producer.send({
            topic: 'order.audit.dlq',
            messages: [{ value: message.value }],
          });
          console.log('Message sent to DLQ: order.audit.dlq');
        } catch (dlqError) {
          console.error('Failed to send to DLQ:', dlqError.message);
          throw dlqError;
        }
      } else {
        await new Promise((resolve) => setTimeout(resolve, 1000 * attempt));
      }
    }
  }
}

async function main() {
  await consumer.connect();
  await producer.connect();
  await consumer.subscribe({ topic: 'order.events', fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      await handleMessage(message);
    },
  });
}

process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await consumer.disconnect();
  await producer.disconnect();
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down...');
  await consumer.disconnect();
  await producer.disconnect();
  await prisma.$disconnect();
  process.exit(0);
});

main().catch(async (error) => {
  console.error('Error in consumer:', error);
  await consumer.disconnect();
  await producer.disconnect();
  await prisma.$disconnect();
  process.exit(1);
});


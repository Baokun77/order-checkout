const { Kafka } = require('kafkajs');
const { prisma } = require('./db/client');

const kafka = new Kafka({
  clientId: 'audit-service',
  brokers: ['localhost:9092'],
});

const consumer = kafka.consumer({ groupId: 'audit-group' });

async function main() {
  await consumer.connect();
  await consumer.subscribe({ topic: 'order.events', fromBeginning: false });

  await consumer.run({
    eachMessage: async ({ message }) => {
      const event = JSON.parse(message.value.toString());
      console.log('Received event', event);

      await prisma.auditLog.create({
        data: {
          orderId: event.orderId,
          payload: event,
          createdAt: new Date(),
        },
      });
    },
  });
}

process.on('SIGINT', async () => {
  console.log('Shutting down...');
  await consumer.disconnect();
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  console.log('Shutting down...');
  await consumer.disconnect();
  await prisma.$disconnect();
  process.exit(0);
});

main().catch(async (error) => {
  console.error('Error in consumer:', error);
  await consumer.disconnect();
  await prisma.$disconnect();
  process.exit(1);
});

